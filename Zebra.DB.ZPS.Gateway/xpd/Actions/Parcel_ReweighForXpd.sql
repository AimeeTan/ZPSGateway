/*
@slip	= at.Duad.Join(Mic, Weight).Over(at.Tvp.Many)
@context= Source
@result	= at.Many.Join(ParcelID)
*/
-- Aimee
CREATE PROCEDURE [xpd].[Parcel$ReweighForXpd](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
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
			MatterID    dbo.I64     NOT NULL,
			MeasureWt   real        NOT NULL,
			SvcClass    dbo.E8      NOT NULL,
			NewSvcClass dbo.E8      NOT NULL,
			IsOverLabel bit         NOT NULL
		);
		insert	@parcelSpec
		(		  MatterID, MeasureWt,  SvcClass, NewSvcClass, IsOverLabel)
		select	m.MatterID, x.v2,     p.SvcClass,  c.SvcClass, iif(p.SvcClass=c.SvcClass, 0, 1)
		from	tvp.Duad#Slice(@slip, default, default)           x
		cross	apply core.RefNbr#ScanOne(x.v1, default, default) m
		join	shpt.Parcel#Base() p on p.ID=m.MatterID
		cross	apply tms.SvcClass#For(p.SvcType, x.v2) c
		;

		if (select count(1) from @parcelSpec where IsOverLabel=1)>0 -- 
		begin
			declare	@svcClassLW dbo.E8=13, @svcClassPS dbo.E8=14;
			declare	@postCourierSpec as table
			(
				MatterID    dbo.I64     NOT NULL,
				SvcClass    dbo.E8      NOT NULL,
				Type        dbo.E8      NOT NULL,--RefNbr Type
				PostCourier varchar(40) NOT NULL
			);
			insert	@postCourierSpec
			(		  MatterID,   Type, PostCourier, SvcClass)
			select	x.MatterID, x.Type, x.Number,    iif(x.Type=t.PostCourierPrevious, @svcClassLW, @svcClassPS)
			from	core._RefNbr x cross apply core.RefNbr#Type() t
			join	@parcelSpec  o on o.MatterID=x.MatterID and o.IsOverLabel=1 
			where	x.Type in(t.PostCourierPrevious, t.PostCourierOriginal)
			;

			declare	@newPicParcelIDSeqs I64AutoSeqs;
			insert	@newPicParcelIDSeqs(ID) select MatterID
			from	@parcelSpec x where x.IsOverLabel=1
			and		not exists
			(
					select	MatterID from @postCourierSpec t 
					where	t.MatterID=x.MatterID and t.SvcClass=x.NewSvcClass
			);
			
			--	2.1	Init Pic Spec
			declare	@picSpec tms.PicSpec; insert @picSpec
			(		  MeasuredWt,  SvcType,   Zip3,   Plus2)
			select	t.MeasureWt, p.SvcType, z.Zip3, z.Plus2
			from	@newPicParcelIDSeqs x
			join	@parcelSpec t on t.MatterID=x.ID
			join	shpt.Parcel#Base() p on p.ID=x.ID
			cross	apply tms.ZoneCode#For(p.ZoneCode) z
			;

			--	2.2	Emit PICs:
			declare	@picResult tms.PicResult; insert @picResult
			exec	tms.Pic#Emit @source=@source, @picSpec=@picSpec
			;
			-- HACK TYPE
			insert	@postCourierSpec
			(		MatterID,   SvcClass, PostCourier,   Type)
			select	    x.ID, p.SvcClass, t.TrackingNbr, iif(p.SvcClass=@svcClassLW, r.PostCourierPrevious, r.PostCourierOriginal)
			from	@newPicParcelIDSeqs x cross apply core.RefNbr#Type() r
			join	@picResult p on p.SeqNbr=x.Seq
			cross	apply tms.TrackingNbr#Make(p.SvcCode, p.MailerID, p.MailerSeq, x.ID) t
			;

			-- Insert PostCourierPre Or PostCourierOrg
			insert	core._RefNbr
			(		  MatterID, Type, Number) 
			select	x.MatterID, Type, PostCourier
			from	@postCourierSpec x join @parcelSpec t on t.MatterID=x.MatterID
			where	x.SvcClass=t.NewSvcClass
			and		exists(select p.ID from @newPicParcelIDSeqs p where p.ID=x.MatterID)
			;

			-- Upd PostCourier
			update	x set x.Number=p.PostCourier
			from	core._RefNbr     x cross apply core.RefNbr#Type() t
			join	@parcelSpec      o on o.MatterID=x.MatterID and o.IsOverLabel=1
			join	@postCourierSpec p on p.MatterID=x.MatterID and p.SvcClass=o.NewSvcClass
			where	x.Type=t.PostCourier
			;
		end

		-- Upd Parccel
		update	p set p.Weight=x.MeasureWt, p.SvcClass=x.NewSvcClass
		from	shpt._Parcel p join @parcelSpec  x on x.MatterID=p.ID
		;

		-- 6.	result
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
