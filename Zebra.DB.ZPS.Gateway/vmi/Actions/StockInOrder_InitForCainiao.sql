/*
@slip  =CainiaoASNNbr
@result=Duad<MatterID, AsnNbr>
*/
--Smile
CREATE PROCEDURE [vmi].[StockInOrder$InitForCainiao](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
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
		declare	@type      E8=(select  StockInOrder      from core.Matter#Type());
		declare	@source    E8=(select  eVMI              from core.Source#ID());
		declare	@stateID   I32=(select AsnImported=11220 from core.State#ID());
		declare	@stage     E32=(select Stage  from core.Stage#Of(@stateID));
		declare	@matterID  I64=next value for core.MatterSeq;
		declare @asnNbr    loc.RefNbr=(@slip);

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