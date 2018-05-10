--PeterHo, Aimee
CREATE FUNCTION [svc].[Sku$DutyList]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID, x.TenantID, TenantAlias=p.Alias, x.SkuNbr, t.DutyTvp
	from	invt.Sku#Raw()    x
	join	core.Tenant#Raw() p on p.ID= x.TenantID
	cross	apply invt.SkuDuty#Tvp(x.ID) t
)
