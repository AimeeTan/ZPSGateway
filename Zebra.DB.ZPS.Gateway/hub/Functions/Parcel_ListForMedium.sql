-- Smile
CREATE FUNCTION [hub].[Parcel$ListForMedium](@unityID bigint)
RETURNS TABLE
--WITH ENCRYPTION
AS RETURN 
(
	select	ID, StateID, RefNbrs, RefInfos
	from	shpt.Parcel#Base() p
	where	p.AID=@unityID
)