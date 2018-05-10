/*
@slip = Field <PID, AID, Alias, Contact, UtcPlace, UtcOffset>
@context=Dozen<Source, DutyTerms, NoDutyTerms, BillingCycle, 
			   EffectiveOn, ExpiredOn, BIZUnitID,
			   Many[SvcType], Many[FileID]>
*/
--Smile
CREATE PROCEDURE [svc].[Tenancy$AddTenant](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET	XACT_ABORT ON;
	BEGIN TRY
		BEGIN TRAN;

		declare	@source E8,  
			@dutyTerms tinyint,  @nondutyTerms tinyint, @billingCycle tinyint,
			@effectiveOn dbo.DT, @expiredOn dbo.DT, 
			@bizUnitID I32, @svcTypes tvp, @fileBankIDs tvp;

		select	@source=v1,
				@dutyTerms=v2,   @nondutyTerms=v3, @billingCycle=v4,
				@effectiveOn=v5, @expiredOn=v6,
				@bizUnitID=v7,   @svcTypes=v8, @fileBankIDs=v9
		from	tvp.Dozen#Of(@context, default);

		declare	@id I64, @type E32=(select Tenant from core.Party#Type())
		execute	core.Tenant#Add @id=@id out, @source=@source, @type=@type, @slip=@slip;

		declare	@contractID I32;
		insert	acct._Contract
				(TenantID, BizUnitID,  SourceID, BillingCycle,  DutyTerms,  NonDutyTerms,  EffectiveOn,  ExpiredOn)
		values	(@id,     @bizUnitID, @source,  @billingCycle, @dutyTerms, @nondutyTerms, @effectiveOn, @expiredOn)
		;
		select	@contractID=scope_identity();

		declare	@userID I32=(select UserID from	loc.Tenancy#Of(@tenancy)),
				@auxID E32=(select SalesContract from core.Attachment#Type()),
				@regID I32=(select Contract from core.Registry#ID());

		insert	core._Attachment
				( RegID,  RowID,       AuxID,  PosterID,  FileBankID)
		select	 @regID, @contractID, @auxID, @userID,  x.Piece
		from	tvp.Many#Slice(@fileBankIDs) x;

		insert	tms._SvcContract(SvcType, ContractID) select s.Major, @contractID
		from	tvp.Many#Slice(@svcTypes)        x
		cross	apply tms.SvcType#Major(x.Piece) s

		select	@result=Tvp from tvp.Duad#Make(@id, @contractID);

		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END