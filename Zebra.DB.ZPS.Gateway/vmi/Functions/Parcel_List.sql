--Smile
CREATE FUNCTION [vmi].[Parcel$List](@trackingNbr varchar(40))
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	ID, Weight, Source, PostedOn,  Stage,   StateID,  StatedOn
	,		SvcType,    SiteID, SiteAlias, RefNbrs, RefInfos, Ledgers
	from	shpt.Parcel#Deep()     x
	cross	apply core.Source#ID() k
	where	x.Source=k.eVMI
	and		(nullif(@trackingNbr, '') is null
	or		exists (
						select	MatterID from core.RefNbr#Raw()
						where	MatterID=x.ID and Number=@trackingNbr
					))
)