
--Daxia
CREATE FUNCTION [shpt].[SackMft#MawbWtRateCalc](@rate real, @mawbWt float, @pecentKgWt float, @minimum real)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
	select	MawbWtAmt=iif(cast((@rate * (@mawbWt/(@pecentKgWt*1000.0))) as real)>@minimum, cast((@rate * (@mawbWt/1000.0)) as real), @minimum)
)
