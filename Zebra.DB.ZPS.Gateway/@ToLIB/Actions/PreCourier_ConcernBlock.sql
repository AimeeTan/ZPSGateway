/*
	@slip = Entry[Block<***>]
*/
-- AaronLiu
CREATE PROCEDURE [shpt].[PreCourier#ConcernBlock](@index int, @slip tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	
	with	cte as
	(
		select	Tvp=replace(x.Tvp, k.Entry, N',')
		from	tvp.Block#At(@index, @slip, default, default) x
		cross	apply tvp.Spr#Const() k
	)
	select	@slip=Tvp from cte;
	execute	shpt.PreCourier#Concern @slip=@slip;
END