/*
@slip = at.Tvp.Triad.Join(SackMftID, StateID, at.Tvp.Trio.Join(UtcTime, UtcOffset, UtcPlaceID)).Over(at.Tvp.Many.Join)
*/
--Smile
CREATE PROCEDURE [svc].[SackMft$MergeStamp](@slip tvp)
--WITH ENCRYPTION--
AS
BEGIN	
	SET	NOCOUNT ON;
	execute core.RefStamp#Merge @slip=@slip;	
END