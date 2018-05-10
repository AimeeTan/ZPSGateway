--PeterHo
CREATE PROCEDURE [svc].[Parcel$Transit](@idsInCsv tvp, @actionID I32, @tenancy tvp, @beAffected bit=0)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	declare	@userID I32,    @roleID I32;
	select	@userID=UserID, @roleID=RoleID
	from	loc.Tenancy#Of(@tenancy);

	--declare	@expectedCnt int=tvp.Comma@Count(@idsInCsv);
	declare	@spec core.TransitionSpec;
	insert	@spec select t.* from shpt.Parcel#TobeVia(@idsInCsv, @roleID, @actionID) t

	--if (@beAffected=1)
	--execute	dbo.Assert#RowCntEQ @rowCnt=@expectedCnt;

	execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=@beAffected;
END