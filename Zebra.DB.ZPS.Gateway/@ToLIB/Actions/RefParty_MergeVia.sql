--AaronLiu
CREATE PROCEDURE [core].[RefParty#MergeVia](@idsInCsv tvp, @partyRole E8, @partyID E32)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;
	with	cteSlip as
	(
		select	MatterID=cast(Piece as bigint )
		from	tvp.Comma#Slice(@idsInCsv)
	)
	merge	core._RefParty as o using cteSlip as n
	on		(o.MatterID=n.MatterID and o.PartyRole=@partyRole)
	when	matched		and @partyID=0          then delete
	when	matched		and o.PartyID<>@partyID then update set PartyID=@partyID
	when	not matched and @partyID>0			then insert	(  MatterID,  PartyRole,  PartyID)
													 values (n.MatterID, @partyRole, @partyID)
	;
END
GO