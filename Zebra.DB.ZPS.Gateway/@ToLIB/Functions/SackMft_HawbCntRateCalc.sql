--Daxia
CREATE FUNCTION [shpt].[SackMft#HawbCntRateCalc](@sackMftID bigint, @rate real, @minimum real, @limitCnt int)
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS RETURN
(
		with cte as
		(
			select	ParcelCnt=count(*)
			from	core.Matter#PNodeDn(@sackMftID) x
			cross	apply core.Matter#Type() k
			where	x.Type=k.Parcel
		)
		select	HawbAmt=iif(ParcelCnt>@limitCnt,(ParcelCnt-@limitCnt)*@rate+@limitCnt*@minimum, ParcelCnt*@minimum)
		from	cte
)
