/*
@slip = Many[Triad<ID, Type, ContactTvp>]
*/
--AaronLiu
CREATE PROCEDURE [svc].[Contact$Merge](@slip tvp, @tenancy tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@siteID I32;
		select	@siteID=SiteID
		from	loc.Tenancy#Of(@tenancy);

		with	cteNew as
		(
			select	ID=cast(x.v1 as bigint), PartyID=@siteID,  Type=cast(x.v2 as tinyint), Name, Phone
			,		Email, Company, Street1, Street2, Street3, City, District, Province,   PostalCode
			,		CountryCode
			from	tvp.Triad#Slice(@slip, default, default) x
			cross	apply loc.Contact#Of(x.v3)
		)
		,	cteOld as
		(
			select	c.ID,	   c.PartyID, c.Type,	 c.Name,	 c.Phone, c.Email,    c.Company
			,		c.Street1, c.Street2, c.Street3, c.District, c.City,  c.Province, c.PostalCode, c.CountryCode
			from	cteNew x,  core.Contact#Raw() c 
			where	abs(x.ID) =c.ID
		)
		merge	cteOld as o using cteNew as n
		on		o.ID=n.ID
		when	matched then
			update set o.Name=n.Name,		o.Phone=n.Phone,	   o.Email=n.Email,			  o.Company=n.Company
			,		   o.Street1=n.Street1, o.Street2=n.Street2,   o.Street3=n.Street3,		  o.District=n.District
			,		   o.City=n.City,		o.Province=n.Province, o.PostalCode=n.PostalCode, o.CountryCode=n.CountryCode
		when	not matched and n.ID=0 then
			insert(  PartyID,	Type,	   Name,   Phone,	   Email,	   Company,		 Street1
			,		 Street2,   Street3,   City,   District,   Province,   PostalCode,	 CountryCode)
			values(  @siteID, n.Type,	 n.Name, n.Phone,    n.Email,    n.Company,	   n.Street1
			,	   n.Street2, n.Street3, n.City, n.District, n.Province, n.PostalCode, n.CountryCode)
		when	not matched by source then delete
		;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END