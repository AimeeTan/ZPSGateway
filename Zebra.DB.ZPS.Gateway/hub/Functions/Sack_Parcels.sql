-- Eva
CREATE FUNCTION [hub].[Sack#Parcels](@sackID I64)
RETURNS	TABLE
--WITH ENCRYPTION
AS RETURN
(
	select	ParcelCnt = isnull(sum(case when m.Type in (t.Parcel, t.HouseParcel, t.MasterParcel, t.MediumParcel, t.OrphanParcel, t.UnityParcel) then 1 else 0 end),0)
	from	core.Matter#PNodeDn(@sackID) m
	cross	apply core.Matter#Type()     t
)