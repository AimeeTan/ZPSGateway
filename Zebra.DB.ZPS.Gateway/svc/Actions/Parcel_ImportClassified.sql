/*
@slip    = Duad[ParcelID, BrkgInfo]
*/
--Smile
CREATE PROCEDURE [svc].[Parcel$ImportClassified](@slip tvp, @tenancy tvp)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
		
		declare	@ids dbo.I64Array;
		with cteSlip as
		(
			select	MatterID=cast(v1 as bigint), Type=k.BrokerageInfo, Info=v2
			from	tvp.Duad#Slice(@slip, default, default) x
			cross	apply core.RefInfo#Type()               k
		)
		merge	core._RefInfo as o using cteSlip as n
		on		(o.MatterID=n.MatterID and o.Type=n.Type)
		when	matched and len(n.Info)=0     then delete
		when	matched and o.Info<>n.Info    then update set Info=n.Info
		when	not matched and len(n.Info)>0 then insert (  MatterID,   Type,   Info)
												   values (n.MatterID, n.Type, n.Info)
		output inserted.MatterID into @ids;
		;

		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);

		declare	@actionID I32=(select DetermineCmdy from core.Action#ID());
		declare	@spec core.TransitionSpec;
		insert	@spec select t.*
		from	@ids  x
		cross	apply shpt.Parcel#Tobe(x.ID, @roleID, @actionID) t
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=1;

	
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END