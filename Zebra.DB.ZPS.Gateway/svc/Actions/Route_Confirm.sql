/*
@slip = IDs.Over(at.Tvp.Comma.Join)
*/
--Smile
CREATE PROCEDURE [svc].[Route$Confirm](@slip tvp, @tenancy tvp)
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

	declare	@creditExceeded I32, @svcRateNotFound I32, @routeCfm I32;
	select	@creditExceeded=ReportCreditLimitExceeded, @svcRateNotFound=ReportSvcRateNotFound, @routeCfm=ConfirmRoute
	from	core.Action#ID();
	
	declare	@branchSpec core.TransitionSpec; 
	insert	@branchSpec select t.* from shpt.Parcel#TobeVia(@slip, @roleID, @routeCfm) t
	join	core.Matter#Raw() m on m.ID=t.MatterID 
	cross	apply core.Source#ID() k
	cross	apply core.Stage#ID()  s
	where	m.Source=k.eVMI or m.Stage=s.PreScreenParcelCreated;
	if(exists(select Seq from @branchSpec))
		execute	core.Matter#TransitBySpec @spec=@branchSpec, @userID=@userID, @beAffected=1;

	declare	@spec core.TransitionSpec, @specVia core.TransitionSpec;
	insert	@spec select t.* from shpt.Parcel#TobeVia(@slip, @roleID, @routeCfm) t
	
	if(exists(select Seq from @spec))
	begin

		declare	@parcelIDs I64Array;insert	into @parcelIDs(ID)
		select	MatterID from @spec x
		join	shpt.Parcel#Raw()   p on p.ID=x.MatterID
		cross	apply tms.SvcRate#For(p.SvcType, p.RcvHubID, p.Weight) s
		where	s.SvcRate>0
		and		not exists(
								select	ID from acct.Ledger#Raw()  l
								cross	apply acct.Ledger#Side() d
								where	MatterID=x.MatterID and l.LedgerSide=d.AR
						   );
		execute	shpt.Parcel#TalliedOrDeduct @parcelIDs=@parcelIDs;

		with cteCumulation as
		(
			select	x.ID, x.MatterID, x.ChargeRaw,  x.CurrencyID 
			,		CurBalRaw
			,		Cumulation=sum(ChargeRaw) over( partition by x.PartyID, x.CurrencyID order by x.ID desc) 
			from	@spec                    p
			join	acct.Ledger#Raw()        x on p.MatterID=x.MatterID
			cross	apply acct.Ledger#Side() d
			cross	apply (
								select	PartyID, CurrencyID, CurBalRaw=sum(CurBalRaw)
								from	acct.Vault#Raw() 
								where	PartyID=x.PartyID and CurrencyID=x.CurrencyID
								group	by PartyID, CurrencyID
						  ) v
			
			where	x.LedgerSide=d.AR 
		), cteSummary as
		(
			select	MatterID, Marker=(case when CurBalRaw>=0 then 0  										  
										   when CurBalRaw<0 and (Cumulation+CurBalRaw)>ChargeRaw then 0
										   else 1 end)
			,		isSvcRateFound=0
			from	cteCumulation	
			union	all
			select	MatterID, 0, isSvcRateFound=isnull(s.SvcRate, 0)
			from	@spec                    x
			join	shpt.Parcel#Raw()        p on x.MatterID=p.ID
			outer	apply tms.SvcRate#For(p.SvcType, p.RcvHubID, p.Weight) s
		), cteParcelGroup as
		(
			select	MatterID, ParcelGroup=sum(Marker), isSvcRateFound=sum(isSvcRateFound)
			from	cteSummary
			group	by MatterID			
		), cteParcelTodo as
		(
			select	MatterID
			,		ActionID=iif(isSvcRateFound=0, @svcRateNotFound, iif(ParcelGroup=0, @routeCfm, @creditExceeded))
			from	cteParcelGroup
		)
		insert	into @specVia select t.* 
		from	cteParcelTodo x
		cross	apply shpt.Parcel#Tobe(x.MatterID, @roleID, x.ActionID) t;
		
		with	cteMatter as
		(
			select	m.ID, RejoinID, NewRejoinID=m.StateID
			from	core._Matter m
			join	@specVia     v on m.ID=v.MatterID
			where	v.ActionID in (@svcRateNotFound, @creditExceeded)
		)
		update	cteMatter set RejoinID=NewRejoinID;

		execute	core.Matter#TransitBySpec @spec=@specVia, @userID=@userID, @beAffected=1;

	end

	COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END

--/*
--@slip = IDs.Over(at.Tvp.Comma.Join)
--*/
----PeterHo
--CREATE PROCEDURE [svc].[Route$Confirm](@slip tvp, @tenancy tvp)
----WITH ENCRYPTION
--AS
--BEGIN
--	SET NOCOUNT    ON;
--	SET XACT_ABORT ON;
--	BEGIN TRY
--		BEGIN	TRAN;

--	declare	@userID I32,    @roleID I32;
--	select	@userID=UserID, @roleID=RoleID
--	from	loc.Tenancy#Of(@tenancy);

--	declare	@actionID I32=(select ConfirmRoute from core.Action#ID());
--	declare	@spec core.TransitionSpec;
--	insert	@spec select t.* from shpt.Parcel#TobeVia(@slip, @roleID, @actionID) t;

--	declare	@exeSpec core.TransitionSpec;
--	declare	@exceptionAction I32=(select ReportSvcRateNotFound from core.Action#ID());
--	with	cteParcelTodo as
--	(
--		select	ID, ActionID=iif(nullif(SvcRate, 0) is null, @exceptionAction, @actionID)
--		from	shpt.Parcel#Raw() p
--		outer	apply tms.SvcRate#For(p.SvcType, p.RcvHubID, p.Weight) s
--		where	p.ID in (select ID from tvp.I64#Slice(@slip))
--	)
--	insert	@exeSpec select t.*
--	from	cteParcelTodo x
--	cross	apply shpt.Parcel#Tobe(x.ID, @roleID, x.ActionID) t;
--	with	cteMatter as
--	(
--		select	m.ID, RejoinID, NewRejoinID=m.StateID
--		from	core._Matter m
--		join	@exeSpec     v on m.ID=v.MatterID
--		where	v.ActionID=@exceptionAction
--	)
--	update	cteMatter set RejoinID=NewRejoinID;

--	execute	core.Matter#TransitBySpec @spec=@exeSpec, @userID=@userID, @beAffected=1;

	

--	declare	@parcelIDs I64Array;
--	insert	into @parcelIDs(ID)
--	select	MatterID 
--	from	@exeSpec x 
--	where	not exists(select ID from acct.Ledger#Raw() where MatterID=x.MatterID)
--	and		ActionID=@actionID;

--	execute	shpt.Parcel#TalliedOrDeduct @parcelIDs=@parcelIDs;

--	COMMIT	TRAN;
--	END TRY
--	BEGIN CATCH
--		if (xact_state() = -1) ROLLBACK TRAN; throw;
--	END CATCH
--END

