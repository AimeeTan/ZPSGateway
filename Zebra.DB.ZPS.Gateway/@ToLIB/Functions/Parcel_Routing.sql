--AaronLiu
CREATE FUNCTION [shpt].[Parcel#Sorting](@pracelID bigint)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	with	cteScaned as
	(
		select	x.ID,				  x.Stage
		,		r.HasOverthrehold,	  r.HasFlaggedForReturn,  r.HasMeasured,			 r.HasShippingPlan
		,		r.ShouldRackIn,		  r.HasOutgated,		  r.HasOutboundLocked,		 r.ShouldOutbound
		,		r.UndefinedEX,		  r.UndefinedHR
		,		s.HubMeasured,		  s.Racking,			  b.PostMin,				 b.CurMin
--------------------------------------------------------------------------------------------------------------------HACK Add below to Stage#ID()
		,		Overthreshold=10545,  FlaggedForReturn=10550, ShippingPlanCocured=11900, ToRacking=11410
		,		OutboundLocked=18000, OutboundStart=14000
--------------------------------------------------------------------------------------------------------------------HACK Add above to Stage#ID()
		from	core.Matter#Raw()			x
		cross	apply core.Stage#ID()		s
		cross	apply whse.Ramp#Routing()	r
		cross	apply core.Stage#Boundary() b
		where	x.ID=@pracelID
	),	cteSorting as
	(
		select	Code					 from shpt.Parcel#PreSorting(@pracelID)
		union	all
		select	Code=HasOverthrehold	 from cteScaned where Stage=Overthreshold
		union	all						 
		select	Code=HasFlaggedForReturn from cteScaned where Stage=FlaggedForReturn
		union	all						 
		select	Code=HasMeasured		 from cteScaned where Stage=HubMeasured
		union	all						 
		select	Code=HasShippingPlan	 from cteScaned where Stage=ShippingPlanCocured
		union	all						 
		select	Code=ShouldRackIn		 from cteScaned where Stage=ToRacking
		union	all						 
		select	Code=HasOutgated		 from cteScaned where Stage>PostMin
		union	all						 
		select	Code=HasOutboundLocked	 from cteScaned where Stage>OutboundLocked
		union	all						 
		select	Code=ShouldOutbound		 from cteScaned where Stage>OutboundStart
		union	all						 
		select	Code=UndefinedHR		 from cteScaned where Stage>CurMin
		union	all						 
		select	Code=UndefinedEX		 from cteScaned
	)
	select	top(1) Code from cteSorting
)