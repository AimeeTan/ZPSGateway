-- AaronLiu
CREATE FUNCTION [core].[Activity#TrackSpecific](@matterID I64, @stateID I32)
RETURNS TABLE
--WITH  ENCRYPTION
AS RETURN
(
	with cteBase as
	(
		select	a.ID,        a.MatterID
		,		a.StateID,   s.Stage
		,		a.UserID,    UserAlias =p.Alias
		,		a.TalliedOn, UtcPartyID=p.PID
		,		s.IsInternal
		from	core.Activity#Raw() a
		join	core.State#Raw()    s on s.ID=a.StateID
		join	core.Party#Raw()    p on p.ID=a.UserID
		where	a.MatterID=@matterID and a.StateID=@stateID
	)
	, cteMarked as
	(
		select	x.ID,     x.MatterID,  x.StateID, x.Stage,     x.TalliedOn
		,		x.UserID, x.UserAlias, z.UtcTime, z.UtcOffset, z.UtcPlace, z.UtcPlaceID
		from	cteBase   x 
		cross	apply
		(
			select	top(1) UtcTime,  UtcOffset, UtcPlace, UtcPlaceID from
			(
				select	UtcTime,     UtcOffset, UtcPlace, UtcPlaceID
				from	core.RefStamp#Of(x.MatterID, x.StateID)
				UNION	ALL
				select	x.TalliedOn, UtcOffset, UtcPlace, UtcPartyID
				from	core.Tenant#Raw() where ID=x.UtcPartyID
			) y
		) z
	)
	select	ID,     MatterID,  StateID, Stage,     TalliedOn
	,		UserID, UserAlias, UtcTime, UtcOffset, UtcPlace, UtcPlaceID
	from	cteMarked
)