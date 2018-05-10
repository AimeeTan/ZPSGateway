-- Daxia
CREATE FUNCTION [svc].[Parcel$ForUploadIDPicture]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	with cteCneeInfo as
	(
		select	MatterID, Name=c.v1, Phone=c.v2
		from	core.RefInfo#Type() k, core.RefInfo#Raw() x
		cross	apply tvp.Dozen#Of(x.Info, default) c
		where	x.Type=k.CneeInfo
	)
	select	p.ID, Name, Phone, p.RefInfos from cteCneeInfo x
	join	shpt.Parcel#Base() p on p.ID=x.MatterID and p.StateID in(38336, 17250)--USE State#ID
)