/*

@slip = Quad[SvcType, RcvHubID, SectionWt, SvcRate]
@context=Triad<TenantID, SvcType, FileID>

*/
--Smile
CREATE PROCEDURE [bo].[Account$ImportSvcRate](@slip tvp, @context tvp, @tenancy tvp)
WITH ENCRYPTION--
AS
BEGIN
	SET	NOCOUNT    ON;
	SET	XACT_ABORT ON;

		declare	@tenantID I32, @svcType I32, @major I32,      @fileID char(33), @contractID I32;
		select	@tenantID=v1,  @svcType=v2,  @major=t.Major,  @fileID=v3,       @contractID=c.ID
		from	tvp.Triad#Of(@context, default)  x
		cross	apply tms.SvcType#Major(cast(x.v2 as int)) t
		join	core.Party#Raw() p on p.ID=x.v1
		cross	apply acct.Contract#For(p.ID, p.Source) c;

		declare	@svcTypeVia I32;
		with cteSvcType as
		(
			select	x.ID, Marker=null
			from	tms.SvcType#Raw() x
			cross	apply tms.SvcType#Major(x.ID) m
			where	m.Major=@major and TenantID=@tenantID
			UNION ALL
			select	x.ID+1, Marker=lead(x.ID) over(order by ID)
			from	tms.SvcType#Raw() x
			cross	apply tms.SvcType#Major(x.ID) m
			where	m.Major=@major 
		)
		select	top(1) @svcTypeVia=ID from cteSvcType where Marker is null;

		if(exists(select * from tvp.Quad#Slice(@slip, default, default) where v1<>@svcType)) return;

		BEGIN TRY
		BEGIN TRAN;

		if(not exists(select * from tms.SvcType#Raw() where ID=@svcTypeVia))
		begin
		insert tms._SvcType(ID,  TenantID,  CurrencyID, DutyCurrencyID, FallbackPOA, InitStateID, ClrMethodID, CmdyRootID)
		select	   @svcTypeVia, @tenantID,  CurrencyID, DutyCurrencyID, FallbackPOA, InitStateID, ClrMethodID, CmdyRootID
		from	   tms.SvcType#Raw()
		where	   ID=@major;
		end

		delete	from tms._SvcRate where SvcType=@svcTypeVia;
		with cteSvcRate as
		(
			select	RcvHubID=x.v2, SectionWt=x.v3, SvcRate=x.v4
			from	tvp.Quad#Slice(@slip, default, default) x
		)
		insert	tms._SvcRate(SvcType, RcvHubID, SectionWt, SvcRate)
		select			 @svcTypeVia, RcvHubID, SectionWt, SvcRate
		from	cteSvcRate;

		delete	from tms._SvcContract where ContractID=@contractID and SvcType in (@major, @svcTypeVia);
		insert	tms._SvcContract(ContractID, SvcType) values(@contractID, @svcTypeVia);

		declare	@userID I32=(select UserID from	loc.Tenancy#Of(@tenancy)),
				@auxID E32=(select SvcRate from core.Attachment#Type()),
				@regID I32=(select Contract from core.Registry#ID());

		insert	core._Attachment
				( RegID,  RowID,       AuxID,  PosterID,  FileBankID)
		values	( @regID, @contractID, @auxID, @userID,  @fileID);
		
		insert	core._ChangeLog(RegID,       RowID, ChangedBy, ChangedOn)
		select			      SvcRate, @contractID,   @userID, getutcdate()
		from	core.Registry#ID();

		declare	@ids I64Array;
		with cteParcel as
		(
			select	ID, SvcType
			from	shpt.Parcel#Base()                 p
			cross	apply core.Stage#ID()              k
			cross	apply tms.SvcType#Major(p.SvcType) s
			where	p.Stage<k.RouteCfmed and s.Major=@major
			and		ContractID=@contractID
		)
		update	cteParcel set SvcType=@svcTypeVia
		output inserted.ID into @ids;

		declare	@daemon I32=0;
		declare	@actionID I32=(select ImportSvcRate from core.Action#ID());
		declare	@spec core.TransitionSpec;
		insert	@spec select t.* from @ids x
		cross	apply shpt.Parcel#Tobe(x.ID, @daemon, @actionID) t;
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=0;

		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
