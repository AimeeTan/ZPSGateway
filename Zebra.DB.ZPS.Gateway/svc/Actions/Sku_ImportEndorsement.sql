/*
@slip    = at.Tvp.Triad.Join(SkuID, Endorsement, at.Tvp.Duad.Join(DutyCode, DutyRate).Over(at.Tvp.Many.Join)
@context = at.Tvp.Duad.Join(ClrMethodID, BrokerID)
*/
--Smile, PeterHo
CREATE PROCEDURE [svc].[Sku$ImportEndorsement](@slip tvp, @context tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET	XACT_ABORT ON;
	BEGIN TRY
		BEGIN TRAN;	 

		declare	@clrMethodID I32, @brokerID I32;
		select	@clrMethodID=v1,  @brokerID=v2
		from	tvp.Duad#Of(@context, default);
		
		declare	@countryCode char(2)=(select CountryCode from brkg.ClrMethod#Raw() where ID=@clrMethodID);

		--1.	Upsert Duty:
		with cteDuty as
		(
			select	distinct -- ToSmile: Moving to Client-Side.
					DutyCode=cast(d.v1 as varchar(15))
			,		DutyRate=cast(d.v2 as real)
			from	tvp.Triad#Slice  (@slip, default, default) x
			cross	apply tvp.Duad#Of(x.v3,  default) d
		)
		merge	into brkg._Duty as o using cteDuty as n
		on		(o.CountryCode=@countryCode and o.DutyCode=n.DutyCode)
		when	matched	then update set o.DutyRate=n.DutyRate
		when	not matched then insert( CountryCode,   DutyCode,   DutyRate)
				                 values(@countryCode, n.DutyCode, n.DutyRate);

		-- 2.	Upsert SkuBrokerage:
		with cteSkuBrokerage as
		(	
			select	SkuID=cast(x.v1 as int)
			,		ClrMethodID=@clrMethodID, BrokerID=@brokerID, Endorsement=x.v2, DutyID=w.ID
			from	tvp.Triad#Slice  (@slip, default, default) x
			cross	apply tvp.Duad#Of(x.v3,  default)          d
			join	brkg.Duty#Raw() w on w.CountryCode=@countryCode and w.DutyCode=cast(d.v1 as varchar(15))
		)
		merge	into invt._SkuBrokerage as o using cteSkuBrokerage as n 
		on		(o.SkuID=n.SkuID and o.ClrMethodID=n.ClrMethodID and o.BrokerID=n.BrokerID)
		when	matched     then update set o.Endorsement=n.Endorsement, o.DutyID=n.DutyID
		when	not matched then insert(  SkuID,  ClrMethodID,    BrokerID,    DutyID,  Endorsement) 
				                 values(n.SkuID, n.ClrMethodID, n.BrokerID, n.DutyID, n.Endorsement);
		
		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
