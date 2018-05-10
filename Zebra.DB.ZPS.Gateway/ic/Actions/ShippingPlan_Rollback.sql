/*
@slip  = string.Join(at.Tvp.Comma, ids)
*/
--Aimee, Daxia
CREATE PROCEDURE [ic].[ShippingPlan$Rollback](@slip tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	
		declare	@actionID I32=(select FallbackShipping from core.Action#ID());
		execute	svc.Parcel$Transit @idsInCsv=@slip, @actionID=@actionID, @tenancy=@tenancy;

END
