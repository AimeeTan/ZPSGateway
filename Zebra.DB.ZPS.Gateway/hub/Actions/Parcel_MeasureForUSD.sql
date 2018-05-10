/*
	@slip    = Comma<ParcelNbr>
	@context = Quad<Weight, Length, Width, Height>
	@result  = Pair<ParcelID, IsOverlabel>
*/
-- Daxia
CREATE PROCEDURE [hub].[Parcel$MeasureForUSD](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
		
		--	0	Tenancy
		declare	@userID I32,    @roleID I32,    @hubID I32;
		select	@userID=UserID, @roleID=RoleID, @hubID=HubID from loc.Tenancy#Of(@tenancy)
		;
		--	1	Scan RefNbr --From auto.ParcelMeasure
		-- Should Stage between PreMin and CurMax?
		declare	@minStage E32,    @maxStage E32;
		select	@minStage=PreMin, @maxStage=Ended from core.Stage#Boundary()
		;
		declare	@matterID I64=(select MatterID from core.RefNbr#ScanMulti(@slip, @minStage, @maxStage));
		exec	core.Activity#OnceHubAccepted @matterID=@matterID, @userID=@userID
		;
		--	2	Init FedEx
		declare	@measureWt real=(select cast(q.v1 as real) from tvp.Quad#Of(@context, N',') q);
		declare	@source dbo.E8,   @newSvcClass dbo.E8,     @isOverLabel bit;
		select	@source=p.Source, @newSvcClass=c.SvcClass, @isOverLabel=iif(p.SvcClass=c.SvcClass, 0, 1)
		from	shpt.Parcel#Base() p cross apply tms.SvcClass#For(p.SvcType, @measureWt) c
		where	p.ID=@matterID
		;
		if(@isOverLabel=1)
		begin
			declare	@svcClassLW dbo.E8=13, @svcClassPS dbo.E8=14
			;
			--	2	Check All PostCourier
			declare	@postCourierSpec as table
			(
				MatterID    dbo.I64     NOT NULL,
				SvcClass    tinyint     NOT NULL,
				Type        dbo.E8      NOT NULL,--RefNbr Type
				PostCourier varchar(40) NOT NULL
			);
			-- HACK SvcClass
			insert	@postCourierSpec
			(		 MatterID,   Type, PostCourier, SvcClass)
			select	@matterID, x.Type, x.Number,    iif(x.Type=t.PostCourierPrevious, @svcClassLW, @svcClassPS)
			from	core._RefNbr x cross apply core.RefNbr#Type() t
			where	x.MatterID=@matterID and x.Type in(t.PostCourierPrevious, t.PostCourierOriginal)
			;
			if not exists (select PostCourier from @postCourierSpec where SvcClass=@newSvcClass)
			begin
				--	2.1	Init Pic Spec
				declare	@picSpec tms.PicSpec; insert @picSpec
				(		MeasuredWt,   SvcType,   Zip3,   Plus2)
				select	@measureWt, p.SvcType, z.Zip3, z.Plus2
				from	shpt.Parcel#Base() p 
				cross	apply tms.ZoneCode#For(p.ZoneCode) z
				where	p.ID=@matterID
				;
				--	2.2	Emit PICs:
				declare	@picResult tms.PicResult; insert @picResult
				exec	tms.Pic#Emit @source=@source, @picSpec=@picSpec
				;
				-- HACK TYPE
				insert	@postCourierSpec
				(		 MatterID,     SvcClass, PostCourier,   Type)
				select	@matterID, @newSvcClass, t.TrackingNbr, iif(@newSvcClass=@svcClassLW, r.PostCourierPrevious, r.PostCourierOriginal)
				from	@picResult x cross apply core.RefNbr#Type() r
				cross	apply tms.TrackingNbr#Make(x.SvcCode, x.MailerID, x.MailerSeq, @matterID) t
				;

				--	2.3	Insert PostCourierPre Or PostCourierOrg
				insert	core._RefNbr
				(		MatterID, Type, Number) 
				select	MatterID, Type, PostCourier
				from	@postCourierSpec x where SvcClass=@newSvcClass
				;
			end

			--	2.4	Upd PostCourier
			update	x set x.Number=p.PostCourier
			from	core._RefNbr     x cross apply core.RefNbr#Type() t
			join	@postCourierSpec p on p.MatterID=x.MatterID and p.SvcClass=@newSvcClass
			where	x.MatterID=@matterID and x.Type=t.PostCourier
			;
			
			--	2.5	Insert AddOnSvc
			insert	core._AddOnSvc
			(		MatterID, OperatorID, Type,        StartedOn,    EndedOn)
			select	@matterID,     0,   k.OverLabel, getutcdate(), dbo.DT@Empty()
			from	core.AddOnSvc#Type() k

		end
		
		--	3	Upd Weight and SvcClass
		;with cteParcel as
		(
			select	ID, q.v1,   q.v2,   q.v3,  q.v4
			from	tvp.Quad#Of(@context, N',') q, shpt.Parcel#Raw() where ID=@matterID
		)
		update	o set RcvHubID=@hubID, Weight=v1, Length=v2, Width=v3, Height=v4, o.SvcClass=@newSvcClass
		from	shpt._Parcel o join cteParcel n on o.ID=n.ID
		;
		exec	shpt.Parcel#Measure @matterID=@matterID, @tenancy=@tenancy
		;
		select	@result=r.Tvp from tvp.Pair#Make(@matterID, @isOverLabel) r
		;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END