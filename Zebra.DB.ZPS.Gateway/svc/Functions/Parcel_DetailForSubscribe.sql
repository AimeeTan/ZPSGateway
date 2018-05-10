-- AaronLiu
CREATE FUNCTION [svc].[Parcel$DetailForSubscribe](@mic varchar(40))
RETURNS TABLE 
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN 
(
	select	ID=x.MatterID, SubscribeNbr=a.RefNbr
	from	api.ActivitySubscription#Raw() a, core.RefNbr#ScanOne(@mic, default, default) x
	where	x.MatterID=a.MatterID
)