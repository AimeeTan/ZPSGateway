/*
@slip    = at.Tvp.Duad.Join(x.SKU, FiledInfo)).Over(at.MyTvp.Mucho.Join)
@context = TenantID
*/
--Smile, PeterHo
CREATE PROCEDURE [svc].[Sku$Import](@slip tvp, @context tvp, @tenancy tvp)
--WITH ENCRYPTION--
AS
BEGIN
	SET	NOCOUNT ON;
	
	declare	@tenantID I32=@context;
	with cteSku as
	(
		select	s.SkuNbr, FiledInfo=d.v2
		from	tvp.Spr#Const() k
		cross	apply tvp.Duad#Slice(@slip, k.Duad, k.Mucho) d
		cross	apply loc.SkuNbr#Cast(d.v1) s
	)
	merge	into invt._Sku as o using cteSku as n 
	on		(o.TenantID=@tenantID and o.SkuNbr=n.SkuNbr)		
	when	matched	    then update set o.FiledInfo=n.FiledInfo
	when	not matched then insert( TenantID,   SkuNbr,   FiledInfo)
	                         values(@TenantID, n.SkuNbr, n.FiledInfo);
END