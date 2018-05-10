-- Eva
CREATE FUNCTION [zeb].[Party$Type] ()
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	Staff
	,		Member
	,		Operator
	,		Facility=ZebraDiv
	,		AgentStore
	,		Associate
	,		Broker
	,		Courier
	,		Customer
	,		Customs
	,		Port
	,		Tenant
	,		TenantSite
	,		Trucker
	,		ZebraStore
	from	core.Party#Type()
)