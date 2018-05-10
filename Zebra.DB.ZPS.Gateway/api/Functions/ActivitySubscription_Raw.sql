-- AaronLiu
CREATE FUNCTION [api].[ActivitySubscription#Raw]()
RETURNS	TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	MatterID, RefNbr
	from	api._ActivitySubscription
)