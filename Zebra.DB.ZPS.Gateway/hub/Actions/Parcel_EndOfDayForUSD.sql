/*
	@slip	=Triad<RcvHubID, ContainAddOnSvc, OperationDate>
*/
-- Daxia
CREATE PROCEDURE [hub].[Parcel$EndOfDayForUSD](@slip tvp, @tenancy tvp)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
		
		--	0	Tenancy
		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);
		
		declare	@hubID I32,               @containAddOnSvc bit,               @opDate DT;
		select	@hubID=cast(x.v1 as int), @containAddOnSvc=cast(x.v2 as bit), @opDate=x.v3
		from	tvp.Triad#Of(@slip, default) x
		;
		declare	@utcOffset smallint=(select UtcOffset from core.Tenant#Raw() where ID=@hubID);
		declare	@startedOn DT=dateadd(hour, @utcOffset * -1, @opDate);
		declare	@endedOn   DT=dateadd(day, 1, @startedOn);

		--	1	Transition
		declare	@source   E8 =(select USD from core.Source#ID())
		,		@actionID I32=(select EndOfDay from core.Action#ID());

		declare	@spec core.TransitionSpec;
		insert	@spec select t.*
		from	shpt.Parcel#Base() x cross apply core.State#ID() s
		cross	apply shpt.Parcel#Tobe(x.ID, @roleID, @actionID) t
		cross	apply core.AddOnSvc#Exists(x.ID) a
		where	x.StateID in (s.CfmOutGated) and x.Source=@source
		and		x.RcvHubID=@hubID and x.StatedOn>=@startedOn and x.StatedOn<@endedOn
		and		(@containAddOnSvc=1 or a.HasAddOnSvc=0)
		;
	
		exec	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=0;
		
		--	2	Bill
		declare	@parcelIDs dbo.I64Array;
		insert	@parcelIDs (ID) select MatterID from @spec;
		exec	shpt.Parcel#BillForFactor @parcelIDs=@parcelIDs, @hubID=@hubID;
		
		--	6.	Add Parcel Q for FedEx
		insert	core._OutboundQ
		(		ToSource,   QueueType,             MatterID,     StateID)
		select	s.InfoPath, q.MftPostCourierAPI, x.MatterID, x.ToStateID
		from	@spec x, core.Source#ID() s, core.Queue#Type() q
		;


		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END