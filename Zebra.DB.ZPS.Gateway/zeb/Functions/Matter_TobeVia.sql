-- AaronLiu
CREATE FUNCTION [zeb].[Matter$TobeVia](@idsInCsv nvarchar(max), @roleID int, @actionID int)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	-- !!!	DON'T CHANGE THE ORDERS; Sync with core.TransitionSpec. !!!
	select	MatterID =x.ID,      ActionID=@actionID
	,		OnStateID=x.StateID, ToStateID, ToStage, x.Source, OutboundQ, TodoHours
	from	tvp.I64#Slice(@idsInCsv) i join core._Matter x on x.ID=i.ID
	cross	apply core.Transition#Tobe(x.StateID, @roleID, @actionID, x.RejoinID) t
)