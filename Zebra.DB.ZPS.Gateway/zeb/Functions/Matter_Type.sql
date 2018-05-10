-- Eva
CREATE FUNCTION [zeb].[Matter$Type] ()
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	Parcel
	,		Sack
	,		SackMft
	,		Zack
	,		ZackMft
	,		ShippingPlan
	from	core.Matter#Type()
)