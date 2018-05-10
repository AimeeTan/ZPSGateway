/*
	@numbers = Comma<MIC>
*/
-- AaronLiu
CREATE FUNCTION [svc].[Parcel$VerifyForSackMft](@numbers tvp, @tenancy tvp)
RETURNS TABLE
WITH ENCRYPTION
AS RETURN
(
	select	p.ID,       MIC=x.Piece,   p.Stage, p.BrokerID, p.BrokerAlias, p.POA
	,		p.RcvHubID, p.RcvHubAlias, Transitable=iif(b.MatterID is null, 0, 1)
	from	tvp.Comma#Slice(@numbers)      x
	cross	apply core.MIC#IdOf(x.Piece)   m
	join	shpt.Parcel#Deep()			   p on m.MatterID=p.ID
	cross	apply core.Action#ID()         a
	cross	apply loc.Tenancy#Of(@tenancy) t
	outer	apply shpt.Parcel#Maybe(p.ID,  t.RoleID, a.ICManifest) b
)