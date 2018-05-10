-- Eva
CREATE FUNCTION [zeb].[Queue$Type]()
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	StateChanged
	,		MeasureReady
	,		ShippingPlanReady
	,		ShippingPlanComplied
	,		BrokerApi
	,		Challenge
	,		PostCourierApi
	,		PreCourierApi
	,		Reminder
	from	core.Queue#Type()
)