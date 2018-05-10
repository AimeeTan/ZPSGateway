/*
@slip		=Count
@context	=courierID
*/
--Eva
CREATE PROCEDURE [svc].[CourierNbr$Fetch](@slip tvp, @context tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	declare	@cnt        E32=cast(@slip as int)
	,		@deletedNbr PcsAutoSeqs;
	with	cte as
	(
		select	top(@cnt) CourierID, TrackingNbr
		from	tms._CourierNbrPool
		where	CourierID=@context
	)
	delete	from cte
	output	deleted.TrackingNbr into @deletedNbr;
	;
	with	cte(text) as
	(
		select	top(@cnt) [text()]=concat(N',', Piece)
		from	@deletedNbr
		for xml path(N'')
	)
	select	@result=Tvp from cte cross apply tvp.Spr#Purify(text, 1);

END