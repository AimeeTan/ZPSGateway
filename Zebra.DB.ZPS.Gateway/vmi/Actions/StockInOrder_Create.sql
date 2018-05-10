﻿/*
@result=Duad<MatterID, AsnNbr>
*/
--Smile
CREATE PROCEDURE [vmi].[StockInOrder$Create](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@userID I32,    @siteID I32;
		select	@userID=UserID, @siteID=SiteID
		from	loc.Tenancy#Of(@tenancy);
		
		declare	@now       DT=getutcdate();
		declare	@type      E8=(select  StockInOrder    from core.Matter#Type());
		declare	@stage     E32=(select InfoImported    from core.Stage#ID());
		declare	@source    E8=(select  eVMI            from core.Source#ID());
		declare	@stateID   I32=(select AsnNbrGenerated from core.State#ID());
		declare	@matterID  I64=next value for core.MatterSeq;
		declare @asnNbr    loc.RefNbr=('VMI_'+format(next value for whse.AsnNbrSeq, '000000000') );

		insert	core._Matter
				(ID,         PosterID,  StateID,  Stage,  Source,  Type, PostedOn)
		values	(@matterID,  @siteID,  @stateID, @stage, @source, @type,     @now);

		insert	whse._StockInOrder
				(       ID, RcvHubID, TotalSkuQty, ContractID)
		select   @matterID,  0,        0,          c.ID
		from	acct.Contract#For(@siteID, @source) c

		insert	core._Activity
				(  MatterID,  StateID,  UserID, TalliedOn)
		values	(@matterID, @stateID, @userID,      @now);

		insert core._RefNbr
		       ( MatterID,  Number, Type)
		select	@matterID, @asnNbr, AsnNbr
		from	core.RefNbr#Type()

		select	@result=Tvp from tvp.Duad#Make(@matterID, @asnNbr);


		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END