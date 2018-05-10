/*
TenantAlias=CustomerCode + " (Admin)"
SiteAlias  =CustomerCode
@slip   = Block[Triad<CustomerCode, UtcOffSet, UtcPlace>, BillingContact, Triad<CustomerCode, UtcOffSet, UtcPlace>, ShippingContact]
@context= Duad<Source, PreAlias>
*/
--Smile
CREATE PROCEDURE [svc].[Tenancy$Import](@slip tvp, @context tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET	XACT_ABORT ON;
	BEGIN TRY
		BEGIN TRAN;

		declare	@source tinyint, @preAlias nvarchar(30);
		select	@source=v1, @preAlias=v2
		from	tvp.Duad#Of(@context, default);

		declare	@idSeqs I64Seqs; insert @idSeqs(ID, Seq)
		select	next value for core.PartySeq, Nbr
		from	dbo.Nbr#Emit(tvp.Entry@Count(@slip));

		-- 1.	Add Tennat && BillingContact:
		declare	@tenantType E8=(select Tenant from core.Party#Type());
		declare	@tenantSeqs I64Seqs;
		with cteParty as
		(
			select	ID=x.Master, PID=0, AID=0, Type=@tenantType, Alias=concat(h.v1, @preAlias), Source=@source, Seq=x.Seq
			from	tvp.Block#FoldT(1, @idSeqs, @slip, default, default) x
			cross	apply tvp.Triad#Slice(x.House, default, default)     h
		
		)
		merge	into core._Party as o using cteParty as n
		on		(o.Alias=n.Alias and o.Source=n.Source)
		when	matched	    then update set  o.PID=n.PID, o.Type=n.Type
		when	not matched then insert(     ID,   PID,   AID,   Type,   Source,    Alias)
									values(n.ID, n.PID,  n.ID, n.Type, n.Source,  n.Alias)
		output inserted.ID, n.Seq into @tenantSeqs
		;
		with cteTenant as
		(
			select	ID=t.ID,  Alias=concat(h.v1, @preAlias), UtcOffset=h.v2, UtcPlace=h.v3
			from	tvp.Block#FoldT(1, @idSeqs, @slip, default, default)  x
			cross	apply tvp.Triad#Slice(x.House, default, default)      h	
			join	@tenantSeqs                                           t on x.Seq=t.Seq
		)
		merge	into core._Tenant as o using cteTenant as n
		on		(o.ID=n.ID)
		when	matched	    then update set o.Alias=n.Alias, o.UtcOffset=n.UtcOffset, o.UtcPlace=n.UtcPlace, o.Source=@source
		when	not matched then insert(     ID,   Alias,   UtcPlace,   UtcOffset, Source)
									values(n.ID, n.Alias, n.UtcPlace, n.UtcOffset, @source)
		;
		--1.1. Add Contract
		insert into acct._Contract
					(TenantID, SourceID,  BillingCycle, DutyTerms, NonDutyTerms,  EffectiveOn,  ExpiredOn)
		select	           ID,  @source,  255,          255,        255,          getutcdate(), dateadd(year, 1, getutcdate())
		from			   @tenantSeqs x
		where			   not exists(select ID from acct.Contract#Raw() where TenantID=x.ID and SourceID=@source)
		;
		declare @billing E8=(select Billing from core.Contact#Type());
		with cteBilling as
		(   
			select	PartyID=i.ID, Type=@billing, Name, Phone, Email, Company, Street1, Street2, Street3, City, District, Province, PostalCode, CountryCode
			from	tvp.Block#FoldT(2, @idSeqs, @slip, default, default)  x
			cross	apply loc.Contact#Of(x.House)                         h
			join	@tenantSeqs                                           i on x.Seq=i.Seq
			where	Name>N''
		)
		merge	into core._Contact as o using cteBilling as n
		on		(o.PartyID=n.PartyID and o.Type=@billing)
		when	matched	    then update set o.PartyID=n.PartyID,  o.Type=n.Type, o.Name=n.Name,  o.Phone=n.Phone,  o.Email=n.Email, o.Company=n.Company, 
											o.Street1=n.Street1,  o.Street2=n.Street2,   o.Street3=n.Street3, o.City=n.City, o.District=n.District,   
											o.Province=n.Province,  o.PostalCode=n.PostalCode,   o.CountryCode=n.CountryCode
		when	not matched then insert(      PartyID,    Type,   Name,  Phone,    Email,   Company,   Street1,   Street2,   Street3,   City,   District,   Province,   PostalCode,   CountryCode)
									values( n.PartyID,  n.Type, n.Name, n.Phone, n.Email, n.Company, n.Street1, n.Street2, n.Street3, n.City,n. District, n.Province, n.PostalCode, n.CountryCode)
		;
		-- 2.	Add Site && Ship from:
		declare	@siteSeq I64Seqs; insert @siteSeq(ID, Seq)
		select	next value for core.PartySeq, Nbr
		from	dbo.Nbr#Emit(tvp.Entry@Count(@slip));
		declare	@siteType E8=(select TenantSite from core.Party#Type());
		declare	@site I64Seqs;
		with	cteParty as
		(
			select	ID=x.Master, PID=t.ID, AID=t.ID, Type=@siteType, Alias=h.v1, Source=@source, Seq=x.Seq
			from	tvp.Block#FoldT(3, @siteSeq, @slip, default, default)  x
			cross	apply tvp.Triad#Slice(x.House, default, default)       h
			join	@tenantSeqs                                            t on x.Seq=t.Seq
		)
		merge	into core._Party as o using cteParty as n
		on		(o.Alias=n.Alias and o.Source=n.Source)
		when	matched     then update set o.Alias=n.Alias
		when	not matched then insert(  ID,   PID,   AID,   Type,   Source,    Alias)
								 values(n.ID, n.PID, n.AID, n.Type, n.Source,  n.Alias)
		output inserted.ID, n.Seq into @site
		;
		with cteSite as
		(
			select	ID=t.ID,  Alias=h.v1, UtcOffset=h.v2, UtcPlace=h.v3
			from	tvp.Block#FoldT(3, @siteSeq, @slip, default, default)  x
			cross	apply tvp.Triad#Slice(x.House, default, default)       h	
			join	@site                                                  t on x.Seq=t.Seq
		)
		merge	into core._Tenant as o using cteSite as n
		on		(o.ID=n.ID)
		when	matched	    then update set o.Alias=n.Alias, o.UtcOffset=n.UtcOffset, o.UtcPlace=n.UtcPlace, o.Source=@source
		when	not matched then insert(  ID,   Alias,   UtcPlace,   UtcOffset, Source)
								 values(n.ID, n.Alias, n.UtcPlace, n.UtcOffset, @source)
		;
		declare @shipper E8=(select Shipping from core.Contact#Type());
		with cteShipper as
		(   
			select	PartyID=i.ID, Type=@shipper, Name, Phone, Email, Company, Street1, Street2, Street3, City, District, Province, PostalCode, CountryCode
			from	tvp.Block#FoldT(4, @siteSeq, @slip, default, default)  x
			cross	apply loc.Contact#Of(x.House)                          h
			join	@site                                                  i on x.Seq=i.Seq
			where	Name>N''
		)
		merge	into core._Contact as o using cteShipper as n
		on		(o.PartyID=n.PartyID and o.Type=@shipper)
		when	matched	    then update set o.PartyID=n.PartyID,  o.Type=n.Type, o.Name=n.Name,  o.Phone=n.Phone,  o.Email=n.Email, o.Company=n.Company, 
											o.Street1=n.Street1,  o.Street2=n.Street2,   o.Street3=n.Street3, o.City=n.City, o.District=n.District,   
											o.Province=n.Province,  o.PostalCode=n.PostalCode,   o.CountryCode=n.CountryCode
		when	not matched then insert(   PartyID,    Type,   Name,  Phone,    Email,   Company,   Street1,   Street2,   Street3,   City,   District,   Province,   PostalCode,   CountryCode)
								 values( n.PartyID,  n.Type, n.Name, n.Phone, n.Email, n.Company, n.Street1, n.Street2, n.Street3, n.City,n. District, n.Province, n.PostalCode, n.CountryCode)
		;
		select @result=count(*) from @tenantSeqs;

COMMIT TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
