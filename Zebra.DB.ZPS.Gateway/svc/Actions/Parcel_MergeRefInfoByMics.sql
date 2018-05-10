/*
@slip   =Many[Triad<MIC, RefInfoType, RefInfo>]
*/
CREATE PROCEDURE [svc].[Parcel$MergeRefInfoByMics](@slip tvp)
WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT ON;	

	declare @refInfoSlip tvp;
	with cteParcel(text) as
	(
		select	[text()]=concat(k.Many, m.MatterID, k.Triad, x.v2, k.Triad, x.v3)
		from	tvp.Triad#Slice(@slip, default, default) x
		cross	apply core.MIC#IdOf(x.v1) m
		join	core.Matter#Raw()         t on t.ID=m.MatterID
		cross	apply core.Stage#ID()     s
		cross	apply tvp.Spr#Const()     k
		where t.Stage=s.RouteAssigned
		for xml path(N'')
	)
	select @refInfoSlip=Tvp from cteParcel cross apply tvp.Spr#Purify(text, default);
	execute core.RefInfo#Merge @slip=@refInfoSlip;

END
