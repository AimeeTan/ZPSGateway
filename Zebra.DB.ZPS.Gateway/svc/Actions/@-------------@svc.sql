CREATE PROCEDURE [svc].[@-------------------@svc]
AS
BEGIN
SET NOCOUNT ON;
/*

@slip    = string.Join(",", TrkNbrs);
@context = at.Quad.Of(POD, POA, Mawb, FlightNbr)
--PeterHo
CREATE PROCEDURE [svc].[HubManifest$Import](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
;

@slip = Items.EachTo(x => x.MIC.Duad(at.Tvp.Pair.Join(x.TrkNbr, x.CourierCode))).Over(at.Tvp.Many.Join);
--PeterHo
CREATE PROCEDURE [svc].[ICManifest$Import](@slip tvp, @tenancy tvp)
;

@slip   = at.Tvp.Duad.Join(ClientRefNbr, IDNbr).Over(at.Tvp.Many)
@result = at.Tvp.Many.Join(NotFoundClientRefNbr)
--Eva, Smile, PeterHo
CREATE PROCEDURE [svc].[IDNbr$Import](@slip tvp, @tenancy tvp, @result tvp out)
;

@slip    tvp=at.Tvp.Comma.Join(TrackingNbrs);
@context tvp=at.Tvp.Triad.Join(ActionID, POA, at.Tvp.Trio.Join(UtcTime, UtcOffSet, UtcPlaceID));
--Smile
CREATE PROCEDURE [svc].[Parcel$CfmCustomsStatus](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
;


--GoodsInfo: Tuplet<Name, Brand, Model, Spec, LineQty, LineTotal>
--SkuInfo  : Mucho[Triad<SkuID, LineQty, LineTotal>]
--3. DeclaredInfo: Mucho[GoodsInfo]
--4. VerifiedInfo: almost same as DeclaredInfo
--7. BrokerageInfo : Duad<{Pair<DutyRate, DutyCode>}, Translated VerifiedInfo>

*/
END