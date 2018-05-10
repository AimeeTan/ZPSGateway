--Smile
CREATE FUNCTION [vmi].[Parcel$ForExport](@siteID int, @trackingNbr varchar(40))
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	ID, Weight, PostedOn,  Stage, RcvHubAlias, CourierAlias
	,		SvcType,    RefNbrs,   RefInfos, Ledgers
	from	shpt.Parcel#Deep()     x
	cross	apply core.Source#ID() k
	where	x.Source=k.eVMI
	and		x.SiteID=@siteID
	and		(nullif(@trackingNbr, '') is null
	or		exists (
						select	MatterID from core.RefNbr#Raw()
						where	MatterID=x.ID and Number=@trackingNbr
					))
)