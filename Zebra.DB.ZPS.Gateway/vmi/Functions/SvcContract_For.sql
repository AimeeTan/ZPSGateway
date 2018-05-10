--Smile
CREATE FUNCTION [vmi].[SvcContract$For](@partyID int)
RETURNS	TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	select	SvcType
	from	core.Party#Raw()                        p
	cross	apply acct.Contract#For(P.ID, p.Source) x
	join	tms.SvcContract#Raw()                   s on s.ContractID=x.ID
	where	p.ID=@partyID and x.ID>0

)