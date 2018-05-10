-- Ken
CREATE FUNCTION [co].[Payment$DetailFor](@paymentID bigint,@toCurrencyID tinyint)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(	
	select PaymentNbr, PaidAmt, ForPayment
	from   acct.Payment#Raw()         x
	join   svc.CurrencyRate$Summary() p on p.ToCurrencyID=@toCurrencyID and p.FmCurrencyID=x.CurrencyID
	where  ID= @paymentID
)
