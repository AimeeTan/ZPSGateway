-- AaronLiu
CREATE FUNCTION [shpt].[Siblings#CntInRack](@parcelID I64)
RETURNS TABLE
-- WITH ENCRYPTION
AS RETURN
(
	with cte as
	(
		select	x.ParcelID, m.AID
		from	shpt.RackXact#Raw()	x, core.Matter#Raw() m
		where	x.ParcelID=m.ID and m.AID>0
	), cteP as
	(
		select	Cnt=count(1)	
		from	cte x, cte m
		where	x.ParcelID=@parcelID and x.AID=m.AID
	)
	select	Cnt
	from	cteP
)