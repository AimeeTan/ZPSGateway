-- AaronLiu
CREATE FUNCTION [hub].[SackLoad$ScanOne](@number varchar(40))
RETURNS	TABLE
--WITH ENCRYPTION
AS RETURN
(
	select	ID,		   s.Stage, StateID, StatedOn, PostedOn, HubID, RefNbrs, SackCnt
	,		TruckerID, Trucker
	from	core.RefNbr#ScanOne(@number, default, default) x
	join	shpt.SackLoad#Base() s on s.ID=x.MatterID
	cross	apply
	(
		select	SackCnt=isnull(sum(case when m.Type=t.Sack then 1 else 0 end),0)
		from	core.Matter#ANodeDn(s.ID) m
		cross	apply core.Matter#Type()  t
	) n
)