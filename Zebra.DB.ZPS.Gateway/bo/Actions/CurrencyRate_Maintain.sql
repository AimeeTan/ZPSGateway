/*
@slip    tvp =Quad[FmCurencyID, ToCurrencyID, ForPayment, ForDeclaration]
*/
--Smile
CREATE PROCEDURE [bo].[CurrencyRate$Maintain](@slip tvp)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	with	cteCurrencyRate as
	(
		select  FmCurrencyID=v1, ToCurrencyID=v2
		,		ForPayment=v3,   ForDeclaration=v4
		from	tvp.Quad#Slice(@slip, default, default) 
	)
	insert	acct._CurrencyRate( FmCurrencyID, ToCurrencyID, ForPayment, ForDeclaration, EffectiveOn)
	select						FmCurrencyID, ToCurrencyID, ForPayment, ForDeclaration, getutcdate()
	from	cteCurrencyRate;
END