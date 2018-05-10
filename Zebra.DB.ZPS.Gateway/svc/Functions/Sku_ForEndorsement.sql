--SmileWang, PeterHo
CREATE FUNCTION [svc].[Sku$ForEndorsement](@clrMethodID int, @brokerID bigint)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	x.ID, TenantID, Alias, SkuNbr, FiledInfo
	,		IsEndorsed=iif(d.DutyID is null, 0, 1)
	from	invt.Sku#Raw()    x
	join	core.Tenant#Raw() t on t.ID=x.TenantID
	left	join invt.SkuBrokerage#Raw() d
	on		d.SkuID=x.ID and d.ClrMethodID=@clrMethodID and d.BrokerID=@brokerID
)
