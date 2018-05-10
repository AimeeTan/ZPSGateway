/*
@slip=  Comma[AsnNbr]
@result=Pair<TenantAlias, Duad[RcvHub, AsnNbr]>
*/
--Smile
CREATE PROCEDURE [vmi].[StockInOrder$Void](@slip tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;

		declare	@userID I32,    @roleID I32,    @tenantAlias loc.Alias;;
		select	@userID=UserID, @roleID=RoleID, @tenantAlias=TenantAlias
		from	loc.Tenancy#Of(@tenancy) x
		join	core.Party#Raw()         p on x.AID=p.ID
		cross	apply loc.TenantAlias#Rectify(p.Alias) t;

	    declare	@actionID I32=(select VoidAsn from core.Action#ID());
		declare	@spec core.TransitionSpec;
		insert	@spec 		
		select	t.* 
		from	loc.RefNbr#Cast(@slip)   x
		cross	apply core.RefNbr#Type() k
		join	core.RefNbr#Raw()        r on r.Number=x.Number and r.Type=k.AsnNbr
		cross	apply core.Matter#Tobe(r.MatterID, @roleID, @actionID) t;
        
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=1;

		with cteResult(text) as
		(
			select	[text()]=concat(k.Many, r.Alias, k.Duad, m.Number)
			from	@spec x
			join	whse.StockInOrder#Raw()  s on s.ID=x.MatterID
			join	core.Party#Raw()         r on r.ID=s.RcvHubID
			cross	apply core.RefNbr#Type() t
			join	core.RefNbr#Raw()        m on m.MatterID=s.ID and m.Type=t.AsnNbr
			cross	apply tvp.Spr#Const()    k
			for		xml path(N'')
		)
		select	@result=r.Tvp 
		from	cteResult 
		cross	apply tvp.Spr#Purify(text, default)  x
		cross	apply tvp.Pair#Make(@tenantAlias, x.Tvp) r
		;
END