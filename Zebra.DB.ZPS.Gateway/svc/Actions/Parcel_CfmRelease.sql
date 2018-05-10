/*
@slip    tvp=Many[Duad<TenantID, ClientRefNbr>]
@result  tvp=Duad<Many[Quad<ID,ClientRefNbr, ServiceType,Stage>],Many[Quad<ID,ClientRefNbr, ServiceType,Stage>]>
*/
--Daxia
CREATE PROCEDURE [svc].[Parcel$CfmRelease](@slip tvp, @tenancy tvp, @result tvp out)
WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET	XACT_ABORT ON;
	BEGIN TRY
		BEGIN TRAN;
		
		declare	@userID I32,    @roleID I32,    @actionID I32;
		select	@userID=UserID, @roleID=RoleID, @actionID=SourceConfirm
		from	loc.Tenancy#Of(@tenancy), core.Action#ID();

		--	1.Parcel Transit
		declare	@spec core.TransitionSpec;
		insert	@spec select t.* 
		from	tvp.Duad#Slice(@slip, default, default) x
		join	core.RefNbr#Raw()      r on r.Number=x.v2
		join	shpt.Parcel#Base()     p on p.ID=r.MatterID and p.SiteID=cast(x.v1 as int)
		cross	apply shpt.Parcel#Tobe(r.MatterID, @roleID, @actionID) t;
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID;

		declare	@clientRef E8=(select ClientRef from core.RefNbr#Type());
		declare	@failure tvp;
		with cteResult(text) as
		(
			select	[text()]=concat(k.Many, c.MatterID, k.Quad, c.Number, k.Quad, p.SvcType, k.Quad, p.Stage)
			from	tvp.Duad#Slice(@slip, default, default) x
			join	core.RefNbr#Raw()     c on c.Number=x.v2 and c.Type=@clientRef
			join	shpt.Parcel#Base()    p on p.ID=c.MatterID
			cross	apply tvp.Spr#Const() k
			where	not exists(select MatterID from @spec where MatterID=c.MatterID)
			for		xml path(N'')
		)
		select	@failure=Tvp from cteResult cross apply tvp.Spr#Purify(text, default);
		with cteSuccess(text) as
		(
			select	[text()]=concat(k.Many, x.MatterID, k.Quad, c.Number, k.Quad, p.SvcType, k.Quad, p.Stage)
			from	@spec                 x
			join	core.RefNbr#Raw()     c on c.MatterID=x.MatterID and c.Type=@clientRef
			join	shpt.Parcel#Base()    p on p.ID=x.MatterID
			cross	apply tvp.Spr#Const() k
			for		xml path(N'')
		)
		select	@result=r.Tvp from cteSuccess 
		cross	apply tvp.Spr#Purify(text, default)  x
		cross	apply tvp.Duad#Make(x.Tvp, @failure) r
		;

		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END