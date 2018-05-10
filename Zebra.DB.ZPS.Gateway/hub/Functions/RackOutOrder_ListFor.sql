-- Smile
CREATE FUNCTION [hub].[RackOutOrder$ListFor](@userID int, @orderID int)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN 
(
	select	ID=ParcelID, ParcelNbr=format(ParcelID %1000000, '000000')
	,		RackID,      RackCode=a.Code
	from	whse.RackOrder#Raw() x
	join	shpt.RackXact#Raw()  r on x.ID=r.OrderOutID
	join	whse.Rack#Raw()      a on a.ID=r.RackID
	where	x.RackerID=@userID and x.ID=@orderID

)