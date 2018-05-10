/*
@slip	= at.Duad.Join(Mic, Weight).Over(at.Tvp.Many)
@context= Source
@result	= at.Many.Join(ParcelID)
*/
-- Daxia
CREATE PROCEDURE [xpd].[Parcel$MeasureForXpd](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
		
		-- 0.	Tenancy & Contexts:
		declare	@siteID I32,    @userID I32,    @roleID I32;
		select	@siteID=SiteID, @userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);

		declare	@source E8=@context;

		-- 1.	Prepare idSeqs
		declare	@parcelSpec as table
		(
			Seq         dbo.I32     NOT NULL,
			MatterID    dbo.I64     NOT NULL,
			MeasureWt   real        NOT NULL,
			SvcClass    dbo.E8      NOT NULL
		);
		insert	@parcelSpec
		(		  Seq,   MatterID, MeasureWt,  SvcClass)
		select	x.Seq, m.MatterID, x.v2,     c.SvcClass
		from	tvp.Duad#Slice(@slip, default, default)           x
		cross	apply core.RefNbr#ScanOne(x.v1, default, default) m
		join	shpt.Parcel#Raw() p on p.ID=m.MatterID
		cross	apply tms.SvcClass#For(p.SvcType, x.v2) c
		;

		-- 2	Prepare PicSpecs:
		declare	@picSpec tms.PicSpec; insert @picSpec
		(		 MeasuredWt,   SvcType,   Zip3,   Plus2)
		select	x.MeasureWt, p.SvcType, z.Zip3, z.Plus2
		from	@parcelSpec x join shpt.Parcel#Raw() p on p.ID=x.MatterID
		cross	apply tms.ZoneCode#For(p.ZoneCode) z;

		-- 3	Emit PICs:
		declare	@picResult tms.PicResult; insert @picResult
		exec	tms.Pic#Emit @source=@source, @picSpec=@picSpec;
		
		declare	@svcClassLW  dbo.E8=13;
		declare	@postCourierSpec as table
		(
			MatterID    dbo.I64     NOT NULL,
			SvcClass    tinyint     NOT NULL,
			Type        dbo.E8      NOT NULL,--RefNbr Type
			PostCourier varchar(40) NOT NULL
		);
		insert	@postCourierSpec
		(		  MatterID,   SvcClass, PostCourier,   Type)
		select	x.MatterID, r.SvcClass, t.TrackingNbr, iif(r.SvcClass=@svcClassLW, k.PostCourierPrevious, k.PostCourierOriginal)
		from	@parcelSpec x join @picResult r on r.SeqNbr=x.Seq
		cross	apply core.RefNbr#Type()  k
		cross	apply tms.TrackingNbr#Make(r.SvcCode, r.MailerID, r.MailerSeq, x.MatterID) t
		;
		
		-- 4.1	Init PostCourierPrevious or PostCourierOriginal
		insert	core._RefNbr
		(		MatterID, Type, Number)
		select	MatterID, Type, PostCourier from @postCourierSpec;

		-- 4.2	Init PostCourier
		insert	core._RefNbr
		(		  MatterID, Type,          Number)
		select	x.MatterID, r.PostCourier, x.PostCourier
		from	@postCourierSpec x cross apply core.RefNbr#Type() r;
		
		-- 5	Upd Parcel Weight
		update	o set o.Weight=n.MeasureWt, SvcClass=n.SvcClass
		from	shpt._Parcel o join @parcelSpec n on n.MatterID=o.ID;

		-- 6	Transit
		declare	@actionID    I32=(select HubMeasure from core.Action#ID())
		,		@idsInCsv    tvp
		,		@idArray     I64Array;
		insert	@idArray(ID) select MatterID from @parcelSpec;
		select	@idsInCsv=x.Tvp from tvp.I64#Join(@idArray) x;
		
		exec	svc.Parcel$Transit @idsInCsv=@idsInCsv, @actionID=@actionID, @tenancy=@tenancy;

		-- 7.	result
		with cteResult(text) as
		(
			select	[text()]=concat(k.Many, x.MatterID)
			from	tvp.Spr#Const() k, @parcelSpec x
			for		xml path(N'')
		)
		select	@result=x.Tvp from cteResult 
		cross	apply tvp.Spr#Purify(text, default)  x
		;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
