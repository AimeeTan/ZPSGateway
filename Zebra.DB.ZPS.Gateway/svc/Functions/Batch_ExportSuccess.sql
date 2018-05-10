--Simile, PeterHo
CREATE FUNCTION [svc].[Batch$ExportSuccess](@batchID bigint)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	n.RefNbrs, CneeInfo=i.Info, PostedOn=l.LocalTime
	from	shpt.Parcel#Base()          x
	cross	apply core.RefInfo#Type()   t
	join	core.RefInfo#Raw()          i on i.MatterID=x.ID and i.Type=t.CneeInfo
	cross	apply core.RefNbr#Tvp(x.ID) n
	cross	apply dbo.DT#ToLocal(x.PostedOn, x.SiteUtcOffset) l
	where	x.BatchID=@batchID
)
