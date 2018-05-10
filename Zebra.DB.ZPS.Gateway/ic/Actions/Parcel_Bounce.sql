/*
@slip	tvp=string.Join(at.Tvp.Comma, TrackingNbrs)
@result	tvp=Many[Duad<UnReturnID, TrackingNbr>]
*/
--Aimee
CREATE PROCEDURE [ic].[Parcel$Bounce](@slip tvp, @tenancy tvp, @result tvp out)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		--	0.	Tenancy:
		declare	@userID I32,    @roleID I32,    @actionID I32;
		select	@userID=UserID, @roleID=RoleID, @actionID=Bounce
		from	loc.Tenancy#Of(@tenancy), core.Action#ID();

		--	1.	Ids
		declare @ids I64Array;
		insert	@ids select distinct m.MatterID
		from	tvp.Comma#Slice(@slip)        x
		cross	apply core.MIC#IdOf(x.Piece)  m

		--	3.	Parcel Transit
		declare	@spec core.TransitionSpec;
		insert	@spec select t.* from @ids x
		cross	apply shpt.Parcel#Tobe(x.ID, @roleID, @actionID) t
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID;
		
		--	4.	Result
		with cteResult(text) as
		(
			select	[text()]=concat(k.Many, x.Piece)
			from	tvp.Comma#Slice(@slip)       x
			outer	apply core.MIC#IdOf(x.Piece) m
			cross	apply tvp.Spr#Const()        k
			where	not exists(select MatterID from @spec where MatterID=m.MatterID)
			for		xml path(N'')
		)
		select	@result=Tvp from cteResult cross apply tvp.Spr#Purify(text, default);

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
