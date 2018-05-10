/*
@slip =  at.Tvp.Field.Join(PartyID, Alias, Contact, UtcPlace, UtcOffset)
@context=Source
*/
--Smile
CREATE PROCEDURE [svc].[Tenancy$UpdateContact](@slip tvp, @context tvp)
WITH ENCRYPTION--
AS
BEGIN
	SET	NOCOUNT    ON;
	SET	XACT_ABORT ON;
	BEGIN TRY
		BEGIN TRAN;

		declare	@partyID int, @alias loc.Alias, @contact tvp, @utcPlace loc.Alias, @utcOffset smallint;

		select	@partyID=v1, @alias=v2, @contact=v3, @utcPlace=v4, @utcOffset=v5
		from	tvp.Field#Of(@slip, default);

		update	core._Tenant set UtcOffset=@utcOffset, UtcPlace=@utcPlace where ID=@partyID;

		with cteContact as
		(
			select	PartyID=@partyID, Type=cast(x.v1 as tinyint), Name, Phone, Email, Company, 
					Street1, Street2, Street3, City, District, Province, PostalCode, CountryCode
			from	tvp.Duad#Slice(@contact, default, default) x
			cross	apply loc.Contact#Of(x.v2)
		)
		merge	into core._Contact as o using cteContact as n
		on		(o.PartyID=n.PartyID and o.Type=n.Type)
		when	matched	    then update set o.PartyID=n.PartyID, o.Type=n.Type,         o.Name=n.Name, 
											o.Phone=n.Phone,     o.Email=n.Email,       o.Company=n.Company, 
											o.Street1=n.Street1, o.Street2=n.Street2,   o.Street3=n.Street3, 
											o.City=n.City,       o.District=n.District, o.Province=n.Province,  
											o.PostalCode=n.PostalCode, o.CountryCode=n.CountryCode
		when	not matched then insert(  PartyID,   Type,   Name,   Phone,  Email,   Company,   
										  Street1,   Street2,   Street3,   City,  District,    Province,   PostalCode,   CountryCode)
								 values(n.PartyID, n.Type, n.Name, n.Phone, n.Email, n.Company, 
										n.Street1, n.Street2, n.Street3, n.City, n.District, n.Province, n.PostalCode, n.CountryCode)
		;

		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
