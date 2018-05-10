-- Smile
CREATE FUNCTION [svc].[Account$ForCreditLimitExceeded]()
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	with cteSummary as
	(
		select	a.ID, a.Alias, x.HandlerID, ParcelCnt=count(*), MinStatedOn=min(x.StatedOn)
		from	core.State#ID() k, shpt.Parcel#Base() x
		join	core.Party#Raw()   p on x.ID=p.ID
		join	core.Party#Raw()   a on a.ID=p.AID
		where	x.StateID=k.CreditLimitExceeded
		group	by a.ID, a.Alias, x.HandlerID
	)
	select	x.ID, TenantAlias=x.Alias, HandlerID, Handler=u.Alias, Name, Phone, Email
	,		ParcelCnt=isnull(ParcelCnt, 0), MinStatedOn
	from	cteSummary                x
	join	core.User#Raw()           u on u.ID=x.HandlerID
	cross	apply core.Contact#Type() t
	join	core.Contact#Raw()   c on c.PartyID=x.ID and c.Type=t.Billing

)
