﻿---- Aimee, TODO: CLEAN.
--Create FUNCTION [svc].[Parcel$ForInventoryCfm](@stage tinyint)
--RETURNS TABLE
--WITH SCHEMABINDING--, ENCRYPTION
--AS RETURN
--(
--	select	ID, Stage, Source, POA, Weight, RefNbrs,RouteCode, SiteAlias, RefInfos
--	from	[shpt].[Parcel#Deep]()
--	where	Stage=@stage
--)