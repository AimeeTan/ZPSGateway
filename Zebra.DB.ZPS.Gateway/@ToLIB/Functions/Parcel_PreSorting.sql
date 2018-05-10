--AaronLiu
CREATE FUNCTION [shpt].[Parcel#PreSorting](@pracelID bigint)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	with	cteScaned as
	(
		select	x.ID,		  x.Stage
		,		r.HasConcern, r.HasChallenge, r.HasAddOnSvc
		from	whse.Ramp#Routing() r, core.Matter#Raw() x
		where	x.ID=@pracelID
	),	cteSorting as
	(
		select	Code=NotFound
		from	whse.Ramp#Routing()
		where	@pracelID is null
		union	all
		select	Code=x.HasConcern
		from	cteScaned x
		cross	apply core.Concern#Exists(x.ID) c
		where	c.HasConcern=1
		union	all
		select	Code=x.HasChallenge
		from	cteScaned x
		cross	apply core.Challenge#Exists(x.ID) c
		where	c.HasChallenge=1
		union	all
		select	Code=x.HasAddOnSvc
		from	cteScaned x
		cross	apply core.AddOnSvc#Exists(x.ID) a
		where	a.HasAddOnSvc=1
	)
	select	top(1) Code from cteSorting
)