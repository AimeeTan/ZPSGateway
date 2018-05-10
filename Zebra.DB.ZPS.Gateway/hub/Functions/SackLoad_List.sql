-- AaronLiu
CREATE FUNCTION [hub].[SackLoad$List]()
RETURNS	TABLE
--WITH ENCRYPTION
AS RETURN
(
	select	ID, Stage, StateID, StatedOn, PostedOn, HubID, RefNbrs, SackCnt
	,		TruckerID, Trucker
	from	shpt.SackLoad#Base() x
	cross	apply
	(
		select	SackCnt=isnull(sum(case when m.Type=t.Sack then 1 else 0 end),0)
		from	core.Matter#ANodeDn(x.ID) m
		cross	apply core.Matter#Type()  t
	) n
)