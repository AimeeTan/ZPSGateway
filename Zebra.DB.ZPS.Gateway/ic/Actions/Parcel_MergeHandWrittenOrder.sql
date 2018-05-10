/*
@slip    =  Triad[ParcelID, RefInfoType, RefInfo]
@context =  Duad <ParcelID, SvcType>;
*/
--Smile
CREATE PROCEDURE [ic].[Parcel$MergeHandWrittenOrder](@slip tvp, @context tvp, @tenancy tvp)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		execute	core.RefInfo#Merge @slip=@slip;	
		
		declare	@parcelID I64, @svcType I32;
		select	@parcelID=v1,  @svcType=v2
		from	tvp.Duad#Of(@context, default);
		with cteParcel as
		(
			select	p.SvcType, NSvcType=t.ID, 
					p.RouteID, NRouteID=r.RouteID, 
					p.POA, NPOA=r.POA, 
					p.ContractID,  NContractID=c.ID, 
					p.LastMilerID, NLastMilerID=r.CourierID
			from	shpt.Parcel#Base()                           p 
			cross	apply tms.SvcType#For(@svcType, p.SiteID)   t
			cross	apply tms.SvcRoute#For(t.ID, t.FallbackPOA) r
			cross	apply acct.Contract#For(p.SiteID, p.Source) c
			where	p.ID=@parcelID

		)		
		update	cteParcel set SvcType=NSvcType, RouteID=NRouteID, POA=NPOA
		,		ContractID=NContractID, LastMilerID=NLastMilerID;
		
		declare	@actionID I32=(select CompleteParcelInfo from core.Action#ID());
		execute	svc.Parcel$Transit @idsInCsv=@parcelID, @actionID=@actionID, @tenancy=@tenancy;
		
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
