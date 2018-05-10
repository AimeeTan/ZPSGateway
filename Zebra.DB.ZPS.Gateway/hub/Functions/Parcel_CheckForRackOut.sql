-- Smile
CREATE FUNCTION [hub].[Parcel$CheckForRackOut](@number varchar(40), @orderID int, @userID int)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN 
(
	select	d.ID
	from	whse.RackOrder#Raw()    x
	cross	apply core.RefNbr#ScanOne(@number, default, default) m
	join	core.Matter#Raw()       d on d.ID=m.MatterID
	join	shpt.RackXact#Raw()     r on r.OrderOutID=x.ID and r.ParcelID=m.MatterID
	cross	apply core.State#ID()   k
	where	x.ID=@orderID and x.RackerID=@userID and d.StateID=k.TobeRackedOut
	
)