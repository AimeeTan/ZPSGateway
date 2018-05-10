--Smile
CREATE PROCEDURE [shpt].[Parcel#ReleaseByDeposit](@partyID I32, @tenancy tvp)
WITH ENCRYPTION--
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
		
		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);

		declare	@actionID I32=(select CfmPayment from core.Action#ID());
		declare	@spec core.TransitionSpec;
		with	cteCumulation as
		(
			select	x.ID, x.MatterID, x.ChargeRaw,  x.CurrencyID 
			,		CurBalRaw
			,		Cumulation=sum(ChargeRaw) over( partition by x.PartyID, x.CurrencyID order by x.ID desc) 
			from	core.Matter#Raw()          m
			join	core.Party#Raw()           p on p.ID=m.PosterID and p.AID=@partyID
			join	acct.Ledger#Raw()          x on x.MatterID=m.ID
			cross	apply acct.Ledger#Side()   d
			cross	apply (
								select	PartyID, CurrencyID, CurBalRaw=sum(CurBalRaw)
								from	acct.Vault#Raw() 
								where	PartyID=x.PartyID and CurrencyID=x.CurrencyID
								group	by PartyID, CurrencyID
						  ) v
			cross	apply core.State#ID() k
			where	x.LedgerSide=d.AR and StateID=k.CreditLimitExceeded
		), cteSummary as
		(
			select	MatterID, Marker=(case when CurBalRaw>=0 then 0  										  
										   when CurBalRaw<0 and (Cumulation+CurBalRaw)>ChargeRaw then 0
										   else 1 end)
			
			from	cteCumulation	
			
		), cteParcelGroup as
		(
			select	MatterID, ParcelGroup=sum(Marker)
			from	cteSummary
			group	by MatterID			
		)
		insert	@spec select t.*
		from	cteParcelGroup x
		cross	apply shpt.Parcel#Tobe(x.MatterID, @roleID, @actionID) t
		where	x.ParcelGroup=0

		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID, @beAffected=0;
	

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END