--hbd
CREATE FUNCTION [svc].[FileBankID$Lookup](@slip tvp)
RETURNS TABLE
AS RETURN
(		
	select	ID, FileBankID
	from	tvp.Triad#Slice(@slip, default, default) x
	join	core.Attachment#Raw() a 
	on		a.RowID=cast(x.v1 as bigint)
	and		a.RegID=cast(x.v2 as int) 
	and		a.AuxID=cast(x.v3 as int)
)