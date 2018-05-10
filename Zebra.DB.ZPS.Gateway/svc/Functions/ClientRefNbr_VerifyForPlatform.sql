/*
@numbersInCSV =Duad[Alias, ClientRefNbr]
*/
--Smile
CREATE	FUNCTION [svc].[ClientRefNbr$VefityForPlatform](@userID int, @numbersInCSV nvarchar(max))
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	
	select	ID=isnull(c.ID, 0), ClientRefNbr=d.Number
	from	tvp.Duad#Slice(@numbersInCSV, default, default) x
	cross	apply loc.RefNbr#Cast(x.v2)                     d
	cross	apply core.RefNbr#Type()                        k
	join	core.Party#Raw()                                n on n.ID=@userID
	left	join  core.Party#Raw()                          p on p.Source=n.Source and p.Alias=x.v1
	cross	apply(
						select top(1) m.ID 
						from(
								select	b.ID from core.RefNbr#Raw()  r
								join	shpt.Parcel#Base()           b on r.MatterID=b.ID  and b.SiteID=p.ID 
								where	r.Number=d.Number and r.Type=k.ClientRef
								union all
								select	0
						) m
		) c
			
)
