/*
	@slip = Comma<PreCourierNbr>
*/
-- AaronLiu
CREATE PROCEDURE [shpt].[Orphan#Adopt](@slip tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);

		declare	@pairs	  I64Pairs;
		declare	@minStage E32,    @maxStage E32;
		select	@minStage=PreMin, @maxStage=CurMax
		from	core.Stage#Boundary();

		with	cte as
		(
			select	Seq, Number=Piece
			from	tvp.Comma#Slice(@slip)
		),	cteMatched as
		(
			select	x.Seq, n.MatterID, m.Type
			,		MatchedCnt=count(1) over(partition by Seq)
			from	core.RefNbr#Type() t, cte x
			join	core.RefNbr#Raw()  n on x.Number=n.Number 
			join	core.Matter#Raw()  m on n.MatterID=m.ID
			where	n.Type=t.PreCourier and m.Stage between @minStage and @maxStage
		),	ctePair as
		(
			select	Seq, ParcelID=[1], OrphanID=[16] 
			from	cteMatched
			pivot	(max(MatterID) for Type in([1], [16])) p
			where	MatchedCnt=2 and [1] is not null and [16] is not null
		)
		insert	@pairs select ParcelID, OrphanID from ctePair;

		--1.0	Add RackLable for Parcel
		declare	@type		E8=(select RackLabel from core.RefNbr#Type())
		,		@mergeSlip tvp;
		with	cte(text) as
		(
			select	[text()]=concat
			(
				k.Many,	 x.LID, 
				k.Triad, @type, 
				k.Triad, format(x.RID %1000000, '000000')
			)
			from	tvp.Spr#Const() k, @pairs x
			cross	apply core.Stage#ID()	  s
			join	core.Matter#Raw()		  m on m.ID=x.RID
			where	m.Stage=s.Racking for xml path(N'')
		)
		select	@mergeSlip=Tvp from cte cross apply tvp.Spr#Purify(text, default);
		execute	core.RefNbr#Merge @slip=@mergeSlip;
		
		--2.0	Copy activity from Orphan to Parcel
		declare	@measure I32=(select HubMeasure from core.Action#ID());
		with	cte as
		(
			select	l.ID, l.AID,  l.StateID, l.Stage, l.RejoinID, RID
			,		OrphanStateID=r.StateID, OrphanStage=r.Stage, NewRejoinID=t.ToStateID
			from	@pairs x
			join	core.Matter#Raw() l on l.ID=x.LID
			join	core.Matter#Raw() r on r.ID=x.RID
			cross	apply shpt.Parcel#Tobe(x.LID, 0, @measure) t
		)
		update	cte set AID=RID, StateID=OrphanStateID, Stage=OrphanStage, RejoinID=NewRejoinID;
		with	cte as
		(
			select	MatterID=x.LID, StateID, ActionID, UserID, TalliedOn
			from	@pairs x
			join	core.Activity#Raw() a on x.RID=a.MatterID
		)
		insert	core._Activity
		(		MatterID, StateID, ActionID, UserID, TalliedOn)
		select	MatterID, StateID, ActionID, UserID, TalliedOn
		from	cte;
		
		--3.0	Replace Orphan with Parcel in Racking process (RackXact)
		with	cte as
		(
			select	ParcelID, NormalParcelID=x.LID
			from	@pairs x
			join	shpt.RackXact#Raw() r on x.RID=r.ParcelID
		)
		update	cte set ParcelID=NormalParcelID;

		--4.0	Orphan should be Adopted
		declare	@ids tvp;
		with	cte(text) as
		(
			select	[text()]=concat(N',', RID)
			from	@pairs for xml path(N'')
		)
		select	@ids=Tvp from cte cross apply tvp.Spr#Purify(text, 1);

		declare	@adopt I32=(select Adopt from core.Action#ID())
		,		@spec  core.TransitionSpec;
		insert	@spec  select t.* from	shpt.Parcel#TobeVia(@ids, @roleID, @adopt) t;
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID;

		--5.0	Check Pracel(RackedIn) whether meet the requirements for ToBeRackedOut or not
		execute	shpt.Parcel#TryRackOut;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END