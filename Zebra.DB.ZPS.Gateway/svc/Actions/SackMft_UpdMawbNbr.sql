/*
@slip =at.Tvp.Duad.Join(SackMftID, MawbNbr);
*/
--Aimee, Smile
CREATE PROCEDURE [svc].[SackMft$UpdMawbNbr](@slip tvp)
--WITH ENCRYPTION--
AS
BEGIN
	SET NOCOUNT    ON;
	
			with cteSackMft as
			(
				select	x.ID, x.MawbNbr, NewMawbNbr=d.v2
				from	shpt.SackMft#Raw()          x
				join	tvp.Duad#Of(@slip, default) d on x.ID=cast(d.v1 as bigint)
			)
			update	cteSackMft set MawbNbr=NewMawbNbr;
	
END