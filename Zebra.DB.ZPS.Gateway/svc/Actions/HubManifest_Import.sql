﻿/*
@slip    = string.Join(",", TrkNbrs);
@context = at.Quad.Of(POD, POA, Mawb, FlightNbr)
*/
--PeterHo
CREATE PROCEDURE [svc].[HubManifest$Import](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;

	declare	@ids I64Array;
	insert	@ids (ID) 
	select	distinct t.MatterID
	from	loc.RefNbr#Slice(@slip)   x
	cross	apply core.RefNbr#ScanOne(x.Number, default, default) t;

	if (not exists(select * from @ids)) return;

	BEGIN TRY
		BEGIN	TRAN;

		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);

		declare	@sackMftID I64;
		execute	shpt.SackMft#Create @id=@sackMftID out, @context=@context, @tenancy=@tenancy;

		declare	@actionID  I32=(select ImportHubManifest from core.Action#ID());
		declare	@spec core.TransitionSpec;
		insert	@spec select t.* from @ids
		cross	apply shpt.Parcel#Maybe(ID, @roleID, @actionID) t;
		execute	core.Matter#TransitBySpecWithPID @spec=@spec, @userID=@userID, @pid=@sackMftID;

		select	@result=(select count(*) from @spec);

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END