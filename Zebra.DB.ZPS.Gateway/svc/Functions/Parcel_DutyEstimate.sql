-- AaronLiu
CREATE FUNCTION [svc].[Parcel$DutyEstimate](@parcelID I64, @brokerageInfo tvp)
RETURNS TABLE
--WITH	ENCRYPTION
AS RETURN
(
	select	d.DutyRate
	from	shpt.Parcel#Base() x
	join	tms.SvcType#Raw()  t on t.ID=x.SvcType
	join	core.Party#Raw()   p on p.ID=x.SiteID
	cross	apply brkg.DutyRate#For(p.AID, t.ClrMethodID, @brokerageInfo) d
	where	x.ID=@parcelID
)