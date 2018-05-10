--Smile, PeterHo
CREATE FUNCTION [svc].[Batch$ExportError](@batchID bigint)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	top(1) [Errors]=s.Supplement
	from	core.Registry#ID() r, core.Supplement#Raw() s
	where	s.RegID=r.ParcelBatch and s.RowID=@batchID
)
