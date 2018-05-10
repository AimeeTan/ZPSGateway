CREATE PROCEDURE [app].[@-------------------@app]
AS
BEGIN
SET NOCOUNT ON;
/*

@slip    = at.Tvp.Block.Join(RefNbr, CneeInfo, DeclaredInfo[Triad.Join(SkuID, LineQty, LineTotal).Over(at.Tvp.Mucho)])
             .Over(at.Tvp.Entry)
@context = at.Quad.Join(Source, SvcType, errorCnt, errors)

CREATE PROCEDURE [app].[Parcel$Init](@slip tvp, @context tvp, @tenancy tvp, @result tvp out)
;



*/
END