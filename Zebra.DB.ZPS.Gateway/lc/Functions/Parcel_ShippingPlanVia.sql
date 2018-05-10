-- AaronLiu
CREATE FUNCTION [lc].[Parcel$ShippingPlanVia](@number varchar(40))
RETURNS TABLE
--WITH ENCRYPTION
AS RETURN 
(
	with cteParcel as
	(
		select	ID=x.MatterID, p.Type, p.Stage, ShippingPlan=i.Info
		from	core.Stage#Boundary() b
		cross	apply core.RefNbr#ScanOne(@number, b.Nil, default) x
		join	shpt.Parcel#Base()			p on x.MatterID=p.ID
		cross	apply core.RefInfo#Type()	t
		cross	apply core.RefInfo#Of(p.ID, t.ShippingPlanInfo) i
	), cteComplied(text) as
	(
		select	[text()]=concat(',', m.Number)
		from	cteParcel x
		cross	apply core.RefNbr#Type()		  t
		cross	apply core.Matter#ANodeDn(x.ID)	  p
		cross	apply core.RefNbr#Of(p.ID, t.MIT) m
		where	p.ID>x.ID
		order	by p.ID
		for		xml path(N'')
	)
	select	ID, Type, Stage, ShippingPlan, Complied=s.Tvp
	from	cteParcel x, cteComplied c
	cross	apply tvp.Spr#Purify(c.text, 1) s
)