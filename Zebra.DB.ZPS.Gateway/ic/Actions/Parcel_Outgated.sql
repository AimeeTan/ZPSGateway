/*
@slip		tvp=Entry[Triad<PickupNbr, PickupedOn, Many[Duad<ParcelID, Weight>]>]
@context	tvp=POA
*/
--Daxia
CREATE PROCEDURE [ic].[Parcel$Outgated](@slip tvp, @context tvp, @tenancy tvp)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		--	0.	Tenancy:
		declare	@userID I32,    @roleID I32,    @actionID I32;
		select	@userID=UserID, @roleID=RoleID, @actionID=Bounce
		from	loc.Tenancy#Of(@tenancy), core.Action#ID();
		
		declare	@pod char(3)=@context
		,		@poa char(3)=@context;

		--	1.	Add SackMft
		declare	@sackMftID I64, @mawb tvp=N'', @flightNbr tvp=N'';
		--at.Quad.Of(POD, POA, Mawb, FlightNbr)
		declare	@sackMftContext tvp=(select Tvp from tvp.Quad#Make(@pod, @poa, @mawb, @flightNbr));
		execute	shpt.SackMft#Create @id=@sackMftID out, @context=@sackMftContext, @tenancy=@tenancy;

		--	2.	Add Sack
		exec	ic.Sack#CreateForImport @slip=@slip, @context=@sackMftID, @tenancy=@tenancy;

		--	3.	Add SackLoad
		--	4.	Add SackTransloaded

		--	5.1	Bill -AR
		declare	@hubID I32=(select ID from core.Hub#ByPOA(@poa));
		declare	@parcelIDs I64Array;insert into @parcelIDs(ID)
		select	i.v1 from tvp.Triad#Slice(@slip, default, N'	;	')     x
		cross	apply tvp.Duad#Slice(x.v3, default, default)           i
		join	shpt.Parcel#Raw()   p on p.ID=i.v1
		where	not exists(
					select	ID from acct.Ledger#Raw()  l
					cross	apply acct.Ledger#Side()   d
					where	MatterID=i.v1 and l.LedgerSide=d.AR
				);
		exec	shpt.Parcel#BillForFactor @parcelIDs=@parcelIDs, @hubID=@hubID;

		--	6.	Add SackMft Q for FedEx
		declare	@source   E8=(select InfoPath from core.Source#ID());
		declare	@stateID dbo.E8, @mftPostCourierQType dbo.E8;
		select	@stateID=StateID from shpt.SackMft#Base() where ID=@sackMftID;
		select	@mftPostCourierQType=q.MftPostCourierAPI from core.Queue#Type() q;
		exec	core.OutboundQ#Enqueue @source=@source, @qtype=@mftPostCourierQType, @matterID=@sackMftID, @stateID=@stateID;
		

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
