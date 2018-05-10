--Smile, AaronLiu
CREATE FUNCTION [svc].[Parcel$ListForCainiao]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID,		 x.RcvHubAlias, MIC=m.Number
	,		LastMilerID, LastMilerCode, x.RouteID
	,		PostCourier=isnull(c.Number,    N'')
	,		FlightNbr  =isnull(d.FlightNbr, N'')
	,		POA=isnull(d.POA, N'')
	,		POD=isnull(d.POD, N'')
	from	shpt.Parcel#Deep()       x
	cross	apply core.Matter#Type() mk
	cross	apply core.RefNbr#Type() k
	join	core.RefNbr#Raw()        m on m.MatterID=x.ID and m.Type=k.MIT
	left	join core.RefNbr#Raw()   c on c.MatterID=x.ID and c.Type=k.PostCourier
	outer	apply 
	(
		select	SackMftID=ID 
		from	core.Matter#PNodeUp(x.ID)
		where	Type=mk.SackMft
	) s
	left	join shpt.SackMft#Deep() d on d.ID=s.SackMftID 
)