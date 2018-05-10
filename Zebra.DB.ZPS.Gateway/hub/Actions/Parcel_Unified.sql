/*
	@slip    = Comma[MediumParcelID]
	@context = UnityParcelID
	@result  = Duad<MatterID, MIC>
*/
-- Smile
CREATE PROCEDURE [hub].[Parcel$Unified](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
		
		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);

		declare	@unityID I64=@context;
		declare	@rowCnt int, @expectedCnt int=(select count(*) from core.Matter#Raw() where AID=@unityID);

		declare	@actionID I32=(select Unify from core.Action#ID());
		declare	@spec core.TransitionSpec; insert @spec select t.*
		from	tvp.I64#Slice(@slip) x
		join	core.Matter#Raw()    m on m.ID=x.ID and m.AID=@unityID
		cross	apply shpt.Parcel#Tobe(m.ID, @roleID, @actionID) t;
		select	@rowCnt=@@ROWCOUNT;

		if(@rowCnt<>@expectedCnt) execute dbo.Assert#Fail @msg=N'';
	    
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=1;

		declare	@hubCheckIn I32=(select HubCheckIn from core.Action#ID());
		declare	@specVia core.TransitionSpec; insert @specVia select t.*
		from	shpt.Parcel#Tobe(@unityID, @roleID, @hubCheckIn) t;
		execute	core.Matter#TransitBySpec @spec=@specVia, @userID=@userID, @beAffected=1;

		declare	@declaredInfo tvp;
		with	cte(text) as
		(
			select	[text()]=concat(k.Mucho, i.Info)
			from	tvp.I64#Slice(@slip)      x
			cross	apply core.RefInfo#Type() t
			join	core.RefInfo#Raw()        i on i.MatterID=x.ID and i.Type=t.DeclaredInfo
			cross	apply tvp.Spr#Const()     k
			for		xml path(N'')
		)
		select	@declaredInfo=Tvp from cte cross apply tvp.Spr#Purify(text, default);

		declare	@brkgInfo tvp;
		with	cte(text) as
		(
			select	[text()]=concat(k.Mucho, i.Info)
			from	tvp.I64#Slice(@slip)      x
			cross	apply core.RefInfo#Type() t
			join	core.RefInfo#Raw()        i on i.MatterID=x.ID and i.Type=t.BrokerageInfo
			cross	apply tvp.Spr#Const()     k
			for		xml path(N'')
		)
		select	@brkgInfo=Tvp from cte cross apply tvp.Spr#Purify(text, default);

		declare	@refInfoSlip tvp;
		select	@refInfoSlip=concat( k.Many, @unityID, k.Triad,	t.DeclaredInfo, k.Triad,  @declaredInfo,									
									 k.Many, @unityID, k.Triad, t.BrokerageInfo, k.Triad, @brkgInfo)
		from	core.RefInfo#Type() t, tvp.Spr#Const() k;
		execute	core.RefInfo#Merge @slip=@refInfoSlip;


		select	@result=t.Tvp
		from	core.RefNbr#Type() k, core.RefNbr#Raw()   x
		cross	apply tvp.Duad#Make(x.MatterID, x.Number) t
		where	x.MatterID=@unityID and x.Type=k.MIT


		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END