/*
@slip    = ConcurredInfo: Bag[Pair<ClientRefNbr, InsuranceAmt>]
@context = ParcelID
*/
--Eva, PeterHo
CREATE PROCEDURE [zeb].[ShippingPlan$Concur](@slip tvp, @context tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@parcelID I64=@context;
		declare	@infoSlip tvp=
		(
			select	Tvp   from core.RefInfo#Type()  k
			cross	apply tvp.Triad#Make(@parcelID, k.ConcurredInfo, @slip)
		);
		execute	core.RefInfo#Merge @slip=@infoSlip;

		declare	@userID I32,    @roleID I32,    @actionID I32;
		select	@userID=UserID, @roleID=RoleID, @actionID=SourceConcur
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
