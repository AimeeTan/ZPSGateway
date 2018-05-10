--PeterHo
CREATE FUNCTION [svc].[Commodity$Node](@parentID int)
RETURNS TABLE
WITH SCHEMABINDING--, ENCRYPTION
AS RETURN
(
	with cteCmdy as
	(
		select	x.ID, x.PID, x.DutyID, x.Surcharge
		,		Path=cast(x.Name as nvarchar(max))
		from	brkg.Commodity#Raw()   x
		where	PID=@parentID and @parentID>0
		UNION	ALL
		select	x.ID, x.PID, x.DutyID, x.Surcharge
		,		Path=p.Path + N'	/	' + x.Name
		from	cteCmdy p join brkg.Commodity#Raw() x
		on		p.ID=x.PID
	)
	select	ID    =isnull(x.ID,     0), PID      =isnull(x.PID,       0)
	,		Path  =isnull(x.Path, N''), Surcharge=isnull(x.Surcharge, 0)
	,		DutyID=isnull(x.DutyID, 0), d.DutyRate,      d.DutyCode
	from	cteCmdy  x join brkg.Duty#Raw() d on d.ID=x.DutyID
	where	d.DutyRate>=0
)
