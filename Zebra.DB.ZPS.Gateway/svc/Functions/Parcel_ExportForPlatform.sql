--Ken
CREATE FUNCTION [svc].[Parcel$ForPlatform]()
RETURNS TABLE 
WITH SCHEMABINDING --,ENCRYPTION
AS RETURN 
(
	select	x.ID,  SiteAlias, x.Source, RefNbrs
	,		Stage, PostedOn, StatedOn, CourierAlias
	from   shpt.Parcel#Base()  x
	join   tms.Courier#Raw()   c	ON  c.ID=x.LastMilerID
)
