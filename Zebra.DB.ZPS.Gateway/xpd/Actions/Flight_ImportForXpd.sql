/*
@slip	= Many[Triad<SackNbr, Weight, string.Join(at.Spr.Comma, Mics)>];
@context= Triad<Dozen<POD, ETD, POA, ETA, FlightNbr, AirlineID, BoardedOn>, Dozen<POD, POA, MawbNbr, FlightNbr, OutgatedOn, MawbWt>, ClrMethodID>;
@result	= Pair<SackMftID, Many[Duad<ParcelID, ParcelMic>]>
*/
-- Daxia
CREATE PROCEDURE [xpd].[Flight$ImportForXpd](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;

	BEGIN TRY
		BEGIN	TRAN;

		declare	@userID I32,    @site I32;
		select	@userID=UserID, @site=SiteID
		from	loc.Tenancy#Of(@tenancy);
		
		declare	@source E8=(select XPD from core.Source#ID());
		declare	@flightContext tvp, @sackMftContext tvp, @clrMethodID I32;
		select	@flightContext=v1,  @sackMftContext=v2,  @clrMethodID=v3 
		from	tvp.Triad#Of(@context, default);
		
		
		-- 1.	Add Flight
		declare	@flightID I64;
		execute	tms.Flight#Create @id=@flightID out, @source=@source, @context=@flightContext, @tenancy=@tenancy;

		--TODO: BoardedOn

		-- 2.1	Add SackMft
		declare	@sackMftID I64;
		execute	shpt.SackMft#CreateForFlight @id=@sackMftID out, @flightID=@flightID, @context=@sackMftContext, @tenancy=@tenancy;
		
		-- !!!Move to SackMft Create
		update	m set BrokerID=x.BrokerID
		from	shpt._SackMft m
		join	tms.Route#Raw() x on x.ClrMethodID=@clrMethodID
		join	tms.SvcRoute#Raw() s on s.RouteID=x.ID and s.POA=m.POA
		where	m.ID=@sackMftID;

		-- 2.3	Add SackMft Q for FedEx and AMS
		declare	@stateID dbo.I32, @mftPostCourierQType dbo.E8, @mftBrokerQType dbo.E8;
		select	@stateID=StateID from shpt.SackMft#Base() where ID=@sackMftID;
		select	@mftPostCourierQType=q.MftPostCourierAPI
		,		@mftBrokerQType     =q.MftBrokerAPI
		from	core.Queue#Type() q;
		exec	core.OutboundQ#Enqueue @source=@source, @qtype=@mftPostCourierQType, @matterID=@sackMftID, @stateID=@stateID;
		exec	core.OutboundQ#Enqueue @source=@source, @qtype=@mftBrokerQType,      @matterID=@sackMftID, @stateID=@stateID;
		

		--TODO: OutgatedOn

		-- 3.1	Add Sack & Upd Parcel
		declare	@sackContext tvp=(select Tvp from tvp.Duad#Make(@sackMftID, @clrMethodID));
		declare	@sackIDTexts tvp;-- Many[Duad<SackID, SackNbr>]
		execute	xpd.Sack$CreateForXpd @slip=@slip, @context=@sackContext, @tenancy=@tenancy, @result=@sackIDTexts out;
		
		-- 3.2	Auto Transloaded : Maybe don't use it.
		-- 3.2	Auto Outgated: where OutgatedOn, When if has not 3.2.
		
		-- 4.1	Parcel Bill -AR
		declare	@hubID I32;
		select	@hubID=h.ID from shpt.SackMft#Raw() x cross apply core.Hub#ByPOA(x.POA) h
		where	x.ID=@sackMftID
		;
		declare	@parcelIDs I64Array;insert into @parcelIDs(ID)
		select	r.MatterID from tvp.Triad#Slice(@slip, default, default)   x
		cross	apply tvp.Comma#Slice(x.v3)                          i
		cross	apply core.RefNbr#ScanOne(i.Piece, default, default) r
		join	shpt.Parcel#Raw()   p on p.ID=r.MatterID
		where	not exists(
					select	ID from acct.Ledger#Raw()  l
					cross	apply acct.Ledger#Side()   d
					where	MatterID=r.MatterID and l.LedgerSide=d.AR
				);
		exec	shpt.Parcel#BillForFactor @parcelIDs=@parcelIDs, @hubID=@hubID;
		
		-- 4.2	Manifest Bill -AR
		exec	shpt.SackMft#BillForCharge @sackMftID=@sackMftID;

		-- 5.	Result
		declare	@validIDs I64Array, @invalidIDs I64Array;
		with cteValid as
		(
			select	p.ID, r.Number
			from	core.Matter#Raw() x cross apply core.RefNbr#Type() k
			join	core.Matter#Raw() p on p.PID=x.ID
			join	core.RefNbr#Raw() r on r.MatterID=p.ID and r.Type=k.MIT
			where	x.PID=@sackMftID
		), cteInvalidText(text) as
		(
			select	[text()]=concat(k.Many, isnull(r.MatterID, 0), k.Duad, i.Piece)
			from	tvp.Spr#Const() k, tvp.Triad#Slice(@slip, default, default) x
			cross	apply tvp.Comma#Slice(x.v3)                                 i
			outer	apply core.RefNbr#ScanOne(i.Piece, default, default)        r
			where	not exists (select * from cteValid c where r.MatterID=c.ID)
			for		xml path(N'')
		)
		select	@result=concat(@sackMftID, k.Pair, isnull(stuff(f.text, 1, 3, N''), N''))
		from	cteInvalidText f, tvp.Spr#Const() k
		;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END