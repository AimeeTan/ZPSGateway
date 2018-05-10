-- AaronLiu, Smile
CREATE	FUNCTION [hub].[SackMft$Summary]()
RETURNS	TABLE
WITH ENCRYPTION
AS RETURN
(
	select	ID,       Stage, StateID,   StatedOn,   HubID
	,		BrokerID, POA,   ParcelCnt, UnSackedParcelCnt
	,		SackCnt,  PostedOn
	from	shpt.SackMft#Base()	x
	cross	apply (
		select	SackCnt			  = isnull(sum(case when m.Type=t.Sack   then 1 else 0 end),0)
		,		ParcelCnt		  = isnull(sum(case when m.Type=t.Parcel then 1 else 0 end),0)
		,		UnSackedParcelCnt = isnull(sum(case when m.Type=t.Parcel and m.Level=1 then 1 else 0 end),0)
		from	core.Matter#PNodeDn(x.ID) m
		cross	apply core.Matter#Type()  t
	) n
)