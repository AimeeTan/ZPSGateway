/*
@slip   =Many[Triad<MatterID, RefInfoType, RefInfo>]
*/
CREATE PROCEDURE [svc].[Parcel$MergeRefInfo](@slip tvp)
WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT ON;	

	execute	core.RefInfo#Merge @slip=@slip;	
END
