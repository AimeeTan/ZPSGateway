/*
@slip=Many[Triad<ParcelID, StateID, Trio<UtcTime, UtcOffset, UtcPlaceID>>]
*/
--Smile
CREATE PROCEDURE [ic].[Parcel$MergeStamp](@slip tvp)
WITH ENCRYPTION
AS
BEGIN	
	SET	NOCOUNT ON;

	execute core.RefStamp#Merge @slip=@slip;	

END