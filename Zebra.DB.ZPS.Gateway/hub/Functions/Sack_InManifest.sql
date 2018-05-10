-- AaronLiu
CREATE	FUNCTION [hub].[Sack$InManifest](@sackMftID I64)
RETURNS	TABLE
WITH ENCRYPTION
AS RETURN
(
	select	ID,	 Stage,	   StateID,     StatedOn,      HubID,     ManifestID=PID
	,		POA, BrokerID, ClrMethodID, Weight=SackWt, ParcelCnt, PostedOn
	,		SackNbr=r.Number
	from	shpt.Sack#Base()	     x
	cross	apply core.RefNbr#Type() s
	join	core.Port#Raw()		     a on  x.POA=a.Code
	join	core.RefNbr#Raw()        r on r.MatterID=x.ID and r.Type=s.MIT
	cross	apply (
		select	ParcelCnt = isnull(sum(case when m.Type=t.Parcel then 1 else 0 end),0)
		from	core.Matter#PNodeDn(x.ID) m
		cross	apply core.Matter#Type()  t
	) n
	where	x.PID=@sackMftID
)