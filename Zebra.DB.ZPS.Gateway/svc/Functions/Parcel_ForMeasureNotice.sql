-- Daxia
CREATE FUNCTION [svc].[Parcel$ForMeasureNotice]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	x.ID, x.PID, x.AID, x.Source, x.Type, x.Stage, x.StateID, x.SvcType
	,		RcvHubID,  RcvHubAlias=t.Alias,   t.UtcOffset, t.UtcPlace
	,		Weight,    Length, Width, Height, RefNbrs, ClientRefNbr=isnull(r.Number, N'')
	from	shpt.Parcel#Base()       x
	left	join core.Matter#Raw()   m on m.ID=x.AID
	cross	apply core.RefNbr#Type() k
	left	join core.RefNbr#Raw()   r on r.MatterID=m.ID and r.Type=k.ClientRef
	join	core.Tenant#Raw()        t on t.ID=x.RcvHubID
)