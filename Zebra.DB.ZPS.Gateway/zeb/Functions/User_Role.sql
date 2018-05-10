-- Eva
CREATE FUNCTION [zeb].[User$Role] ()
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	AcctAdmin
	,		AcctMgr
	,		AcctOP
	,		BOAdmin
	,		BOMgr
	,		BOOP
	,		ClientAdmin
	,		ClientMgr
	,		ClientOP
	,		HubAdmin
	,		HubDriver
	,		HubMgr
	,		HubOP
	,		ICAdmin
	,		ICMgr
	,		ICOP
	,		StoreAdmin
	,		StoreMgr
	,		StoreOP
	from	core.User#Role() r
)