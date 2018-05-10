--Eva
CREATE FUNCTION [zeb].[RefInfo$Type]()
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	ShprInfo
	,		CneeInfo
	,		ReturnInfo
	,		IDInfo
	,		DeclaredInfo
	,		VerifiedInfo
	,		BrokerageInfo
	,		ShippingLabelInfo
	,		ShippingPlanInfo
	,		ConcurredInfo
	from	core.RefInfo#Type()
)
