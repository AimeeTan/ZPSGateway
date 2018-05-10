-- AaronLiu
CREATE FUNCTION [shpt].[Siblings#Cnt](@parcelID I64)
RETURNS TABLE
-- WITH ENCRYPTION
AS RETURN
(
	with cte as
	(
		select	Cnt=count(1)
		from	core.Matter#Raw()  x, core.Matter#Raw() m
		where	x.ID=@parcelID and x.AID=m.AID and m.AID>0
	)
	select	Cnt
	from	cte
)