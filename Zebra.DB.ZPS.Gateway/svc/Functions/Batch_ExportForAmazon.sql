--Smile, PeterHo
CREATE FUNCTION [svc].[Batch$ExportForAmazon](@batchIDs nvarchar(max))
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	ID=BatchID, RefNbrs, RefInfos, CourierAlias, SvcType, PostedOn=l.LocalTime
	from	tvp.I64#Slice(@batchIDs) x
	join	shpt.Parcel#Deep()  p on p.BatchID=x.ID
	cross	apply dbo.DT#ToLocal(p.PostedOn, p.SiteUtcOffset) l
)
