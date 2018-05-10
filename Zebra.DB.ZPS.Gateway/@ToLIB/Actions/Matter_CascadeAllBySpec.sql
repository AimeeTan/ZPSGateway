-- AaronLiu, PeterHo
CREATE PROCEDURE [core].[Matter#CascadeAllBySpec](@spec core.TransitionSpec readonly, @userID I32)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID;

		declare	@descendantSpec core.TransitionSpec; insert @descendantSpec
		(		MatterID,   ActionID, OnStateID,   ToStateID,   ToStage,   Source,   TodoHours,   OutboundQ)
		select	    m.ID, x.ActionID, m.StateID, t.ToStateID, t.ToStage, m.Source, t.TodoHours, t.OutboundQ
		from	@spec x cross apply core.Matter#NodeDn (x.MatterID) m
		cross	apply core.Transition#Tobe(m.StateID, 0, x.ActionID, m.RejoinID) t

		execute	core.Matter#TransitBySpec @spec=@descendantSpec, @userID=@userID;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END