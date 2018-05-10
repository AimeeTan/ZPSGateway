-- Smile
CREATE FUNCTION [hub].[Parcel$UnityInfoVia](@number varchar(40))
RETURNS TABLE
--WITH ENCRYPTION
AS RETURN 
(
	select	p.ID, RefNbrs, RefInfos
	from	core.RefNbr#ScanOne(@number, default, default) x
	cross	apply core.Matter#Type()                       k
	join	core.Matter#Raw()                              m on m.ID=x.MatterID and m.Type=k.MediumParcel
	join	shpt.Parcel#Base()                             p on p.ID=m.AID

)