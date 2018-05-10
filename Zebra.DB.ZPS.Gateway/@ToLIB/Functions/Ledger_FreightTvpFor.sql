﻿--Smile.Wang
CREATE FUNCTION [acct].[Ledger#FreightTvpFor](@invoiceID bigint)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	with cte(text) as
	(
		select	[text()]=concat(k.Many, row_number() over(order by (select 0)), k.Dozen, TalliedOn, k.Dozen, r.Number, 
						 k.Dozen, m.Number, k.Dozen, concat(c.City, ', ', c.Province, ', ',c.CountryCode), k.Dozen, 
						 Source, k.Dozen, SvcType, k.Dozen, Weight, k.Dozen, SectionWt, k.Dozen, ChargeAmt)
		--Seq, LedgerDate, ClientRef, MIC, Destination, Source, SvcType, Weight, SectionWt, Duty
		from	acct.Ledger#Raw()            x
		join	shpt.Parcel#Base()           p on p.ID=x.MatterID
		cross	apply core.RefNbr#Type()     rt 
		join	core.RefNbr#Raw()            r on r.MatterID=p.ID and r.Type=rt.ClientRef
		join	core.RefNbr#Raw()            m on m.MatterID=p.ID and m.Type=rt.MIT
		cross	apply core.RefInfo#Type()    ri
		join	core.RefInfo#Raw()           i on i.MatterID=p.ID   and i.Type=ri.CneeInfo
		cross	apply loc.Contact#Of(i.Info) c
		cross	apply tms.SvcRate#For(p.SvcType, p.RcvHubID, p.Weight) a
		cross	apply tvp.Spr#Const()        k
		where   x.InvoiceID=@invoiceID  
		for		xml path(N'')
	)
	select FreightTvp=Tvp from cte cross apply tvp.Spr#Purify(text, default)
)
