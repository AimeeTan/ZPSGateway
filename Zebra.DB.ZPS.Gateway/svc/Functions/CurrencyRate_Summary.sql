--Smile
CREATE FUNCTION [svc].[CurrencyRate$Summary]()
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	with	cteCurrencyRate as
	(
		select	FmCurrencyID, ToCurrencyID, EffectiveOn, ForPayment, ForDeclaration
		,		Marker=Lead(FmCurrencyID) over (partition by FmCurrencyID, ToCurrencyID order by (select 0))
		from	acct.CurrencyRate#Raw()
	)
	select	FmCurrencyID, ToCurrencyID, EffectiveOn, ForPayment, ForDeclaration
	from	cteCurrencyRate
	where	Marker is null
)