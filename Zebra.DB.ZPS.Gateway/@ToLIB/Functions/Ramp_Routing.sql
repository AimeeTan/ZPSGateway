--AaronLiu
CREATE FUNCTION [whse].[Ramp#Routing] ()
RETURNS TABLE
WITH SCHEMABINDING
AS RETURN
(
	--EX------------------------------
	select	10  as NotFound
	,		99	as UndefinedEX
	--HR------------------------------
	,		110	as HasConcern
	,		199	as UndefinedHR
	--OP------------------------------
	,		220	as HasChallenge
	,		221	as HasAddOnSvc
	,		230	as HasOverthrehold
	,		231	as HasFlaggedForReturn
	,		232	as HasMeasured
	,		233 as HasShippingPlan
	,		234	as ShouldRackIn
	,		250	as HasOutgated
	,		251	as HasOutboundLocked
	,		299	as UndefinedOP
	--CD------------------------------
	,		310	as ShouldOutbound
	,		399	as UndefinedCD
)