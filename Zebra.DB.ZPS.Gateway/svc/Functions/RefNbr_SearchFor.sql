-- Daxia, AaronLiu
CREATE FUNCTION [svc].[RefNbr$SearchFor](@number varchar(40))
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	with cteMatched as
	(
		select	MatterID, Type, Number
		from	core.RefNbr#Raw()
		where	Number=@number
	)
	, cteStaged as
	(
		select	x.MatterID, x.Type, x.Number, m.Stage
		from	cteMatched        x
		join	core.Matter#Raw() m on m.ID=x.MatterID
	)
	select	ID=MatterID, RefNbr=Number, Type, Stage
	from	cteStaged

	/*
	select	ID=MatterID, RefNbr=Number, Type, Stage
	from	core.RefNbr#ScanOne(@number, default, default)
	*/
)