/*
@slip    = Many[Duo<CustomCode, Mucho[Duad<x.SKU, FiledInfo>]>]
@context = Source
*/
--Eva, Smile
CREATE PROCEDURE [svc].[Sku$ImportByPlatform](@slip tvp, @context tvp, @tenancy tvp)
--WITH ENCRYPTION--
AS
BEGIN
	SET	NOCOUNT ON;
	
	declare	@source E8=@context;
	with cteSku as
	(
		select	TenantID=t.PID, s.SkuNbr, FiledInfo=d.v2
		from	tvp.Spr#Const()                              k
		cross	apply tvp.Duad#Slice(@slip, k.Duo, k.Many )  c
		cross	apply tvp.Duad#Slice(c.v2,  k.Duad, k.Mucho) d
		cross	apply loc.SkuNbr#Cast(d.v1)                  s
		join	core.Party#Raw()                             t on t.Alias=c.v1 and t.Source=@source		
	)
	merge	into invt._Sku as o using cteSku as n 
	on		(o.TenantID=n.TenantID and o.SkuNbr=n.SkuNbr)
	when	matched	    then update set o.FiledInfo=n.FiledInfo
	when	not matched then insert(  TenantID,   SkuNbr,   FiledInfo)
	                         values(n.TenantID, n.SkuNbr, n.FiledInfo);
END