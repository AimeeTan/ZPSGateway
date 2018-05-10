/*
for 通用增值服务 (拍照,内件清点除外)
@slip    tvp=at.Tvp.Comma.join(AddOnSvcIDs);
@context tvp=Started UtcTime;
@result  tvp=at.Tvp.Comma.join(updatedIDs);
*/
--Eason
CREATE PROCEDURE [svc].[AddOnSvc$Post](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET	XACT_ABORT ON;
	BEGIN TRY
		BEGIN TRAN;
	    
		declare	@ids I64Array, @updatedIds I64Array;
		insert	into @ids select  x.Piece
		from	tvp.Comma#Slice(@slip) x

		declare	@userID I32 = (select UserID from loc.Tenancy#Of(@tenancy));

		with	n as (
				select	x.ID
				from	@ids x
				cross	apply core.AddOnSvc#Type() t
				join	core._AddOnSvc a on  a.ID=x.ID 
				where	a.OperatorID = 0 and a.Type not in (t.TakePhoto, t.Inventory) -- 不为需要操作内容的增值服务
		)
		update	core._AddOnSvc set OperatorID=@userID, StartedOn=@context, EndedOn=GETUTCDATE()
		output	Inserted.ID into @updatedIds
		from	n
		where	core._AddOnSvc.ID=n.ID
		;
				
		with	cte(Text) as
		(
			select	[text()]=concat(N',', ID) from @updatedIds	
			for	xml path(N'')	
		)	
		select	@result=Tvp from cte cross apply tvp.Spr#Purify(text, 1);
	
		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END