/*

@slip =Dozen<Source, DutyTerms, NoDutyTerms, BillingCycle, 
			 EffectiveOn, ExpiredOn, BIZUnitID, Many[SvcType]>
@context=TenantID

*/
--Smile
CREATE PROCEDURE [bo].[Account$UpdateContract](@slip tvp, @context tvp, @tenancy tvp)
WITH ENCRYPTION--
AS
BEGIN
	SET	NOCOUNT    ON;
	SET	XACT_ABORT ON;
	BEGIN TRY
		BEGIN TRAN;

		declare	@source tinyint, @dutyTerms tinyint,  @nondutyTerms tinyint, @billingCycle tinyint,
				@effectiveOn dbo.DT, @expiredOn dbo.DT, 
				@bizUnitID I32, @svcTypes tvp;

		select	@source=v1, @dutyTerms=v2, @nondutyTerms=v3, @billingCycle=v4,
				@effectiveOn=v5, @expiredOn=v6,
				@bizUnitID=v7,   @svcTypes=v8
		from	tvp.Dozen#Of(@slip, default);

		declare	@contractID int, @obillingCycle tinyint;
		select  @contractID=ID,  @obillingCycle=BillingCycle
		from	acct.Contract#For(@context, @source);

		if((@billingCycle<>@obillingCycle) or nullif(@contractID, 0) is null)
		begin
		insert	into acct._Contract
				(TenantID, BizUnitID,  SourceID, BillingCycle,  DutyTerms,  NonDutyTerms,  EffectiveOn,  ExpiredOn)
		values	(@context, @bizUnitID, @source,  @billingCycle, @dutyTerms, @nondutyTerms, @effectiveOn, @expiredOn)
		;
		select	@contractID=scope_identity();
		end
		else
		begin
		update acct._Contract set BizUnitID=@bizUnitID,  BillingCycle=@billingCycle, 
								  DutyTerms=@dutyTerms,  NonDutyTerms=@nondutyTerms,
								  EffectiveOn=@effectiveOn,  ExpiredOn=@expiredOn
		where	ID=@contractID
		end

		delete	from tms._SvcContract where ContractID=@contractID;
		insert	tms._SvcContract(SvcType, ContractID)
		select	isnull(s.ID, k.Major), @contractID
		from	tvp.Many#Slice(@svcTypes)        x
		cross	apply tms.SvcType#Major(x.Piece) k
		outer	apply (
				 select top(1) t.ID
				 from	tms.SvcType#Raw()        t
				 where	t.TenantID=@context 
				 and	t.ID between k.Major and k.Upto

			  )                                  s;
		declare	@userID I32=(select	UserID from	loc.Tenancy#Of(@tenancy));
		insert	core._ChangeLog(RegID, RowID, ChangedBy, ChangedOn)
		select			  SvcContract, @contractID, @userID, getutcdate()
		from	core.Registry#ID();
	


		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
