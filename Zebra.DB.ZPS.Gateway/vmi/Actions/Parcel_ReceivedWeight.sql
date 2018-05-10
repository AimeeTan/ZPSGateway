/*
@slip    = Tuplet[TrackingNbr, Weight, Width, Length, Height]
*/
--Smile
CREATE PROCEDURE [vmi].[Parcel$ReceivedWeight](@slip tvp,  @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

	declare	@daemon I32=0;
	declare	@creditExceeded I32, @svcRateNotFound I32, @actionID I32;
	select	@creditExceeded=ReportCreditLimitExceeded, @svcRateNotFound=ReportSvcRateNotFound, @actionID=WMSProvideOutgoingWeight
	from	core.Action#ID();
	
	declare	@spec core.TransitionSpec, @specVia core.TransitionSpec;
	insert	@spec select t.* from tvp.Tuplet#Slice(@slip, default, default) x
	cross	apply core.RefNbr#ScanOne(x.v1, default, default)     d
	cross	apply shpt.Parcel#TobeVia(d.MatterID, @daemon, @actionID) t;
	

	declare	@parcelIDs I64Array;insert	into @parcelIDs(ID)
	select	MatterID from @spec x
	join	shpt.Parcel#Raw()   p on p.ID=x.MatterID
	cross	apply tms.SvcRate#For(p.SvcType, p.RcvHubID, p.Weight) s
	where	not exists(
							select	ID from acct.Ledger#Raw()  l
							cross	apply acct.Ledger#Side() d
							where	MatterID=x.MatterID and l.LedgerSide=d.AR
						);
	execute	shpt.Parcel#BillForVmi @parcelIDs=@parcelIDs;

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
		select	MatterID, 0, isSvcRateFound=iif(s.SvcRate is null, 0, 1)
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
		,		ActionID=iif(isSvcRateFound=0, @svcRateNotFound, iif(ParcelGroup=0, @actionID, @creditExceeded))
		from	cteParcelGroup
	)
	insert	into @specVia select t.* 
	from	cteParcelTodo x
	cross	apply shpt.Parcel#Tobe(x.MatterID, @daemon, x.ActionID) t;
		
	with	cteMatter as
	(
		select	m.ID, RejoinID, NewRejoinID=s.ToStateID
		from	core._Matter m
		join	@spec        s on m.ID=s.MatterID
		join	@specVia     v on m.ID=v.MatterID
		where	v.ActionID in (@svcRateNotFound, @creditExceeded)
	)
	update	cteMatter set RejoinID=NewRejoinID;

	execute	core.Matter#TransitBySpec @spec=@specVia, @userID=@daemon, @beAffected=1;

	with cteParcel as
	(
		select	p.ID, NewWeight=x.v2, NewWidth=x.v3, NewLength=x.v4, NewHeight=x.v5
		from	tvp.Tuplet#Slice(@slip, default, default)         x
		cross	apply core.RefNbr#ScanOne(x.v1, default, default) s
		join	shpt.Parcel#Raw()                                 p on p.ID=s.MatterID
	)
	update	o set Weight=NewWeight, Height=NewHeight, Length=NewLength, Width=NewWidth
	from	shpt._Parcel o join cteParcel n on o.ID=n.ID;
	

	COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
