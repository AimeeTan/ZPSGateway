/*
@slip	= TrackingNbr
*/
--Smile
CREATE PROCEDURE [hub].[Parcel$ReleaseForUsps](@slip tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	
	declare	@userID I32,    @roleID I32;
	select	@userID=UserID, @roleID=RoleID
	from	loc.Tenancy#Of(@tenancy);

	declare	@actionID  I32=(select ImportHubManifest from core.Action#ID());

	declare	@spec core.TransitionSpec;
	insert	@spec select t.* 
	from	core.RefNbr#ScanOne(@slip, default, default)           x
	cross	apply shpt.Parcel#Tobe(x.MatterID, @roleID, @actionID) t
	
	execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=0;

	
	
END
