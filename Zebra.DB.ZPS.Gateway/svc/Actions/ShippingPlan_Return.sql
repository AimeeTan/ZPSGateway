/*
@slip  =parcelID
*/
--Eva, Daxia
CREATE PROCEDURE [svc].[ShippingPlan$Return](@slip tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@parcelID I64=@slip;

		declare	@userID I32,    @roleID I32,    @actionID I32;
		select	@userID=UserID, @roleID=RoleID, @actionID=FlagForReturn
		from	loc.Tenancy#Of(@tenancy), core.Action#ID();

		declare	@spec core.TransitionSpec;
		insert	@spec select t.* from shpt.Parcel#Tobe(@parcelID, @roleID, @actionID) t;
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
