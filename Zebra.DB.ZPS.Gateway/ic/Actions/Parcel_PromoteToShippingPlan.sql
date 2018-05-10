/*
@slip  = ParcelID
*/
--Eva, PeterHo
CREATE PROCEDURE [ic].[Parcel$PromoteToShippingPlan](@slip tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	declare	@userID I32,    @roleID I32,    @actionID I32;
	select	@userID=UserID, @roleID=RoleID, @actionID=PromoteToShippingPlan
	from	loc.Tenancy#Of(@tenancy), core.Action#ID();

	declare	@parcelID I64=@slip;
	declare	@spec core.TransitionSpec;
	insert	@spec select t.* from shpt.Parcel#Tobe(@parcelID, @roleID, @actionID) t;
	execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID;
END
