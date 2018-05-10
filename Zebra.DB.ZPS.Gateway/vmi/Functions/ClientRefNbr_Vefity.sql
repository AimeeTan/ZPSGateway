--Smile
CREATE	FUNCTION [vmi].[ClientRefNbr$Vefity](@siteID int, @numbersInCsv nvarchar(max))
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(	

		select	ID=isnull(c.ID,0), ClientRefNbr=x.Number
		from	loc.RefNbr#Slice(@numbersInCsv) x
		cross	apply core.RefNbr#Type()        k
		cross	apply(
						select top(1) m.ID 
						from(
								select	p.ID from core.RefNbr#Raw()  r
								join	shpt.Parcel#Base()           p on r.MatterID=p.ID  and p.SiteID=@siteID 
								where	r.Number=x.Number and r.Type=k.ClientRef
								union all
								select	0
						) m
		) c
		
	
	
)
