/*
@slip    = Many[Triad<MIC, PostCourier, LocalTime>];
*/
--Smile
CREATE PROCEDURE [svc].[HubManifest$ImportForUSPS](@slip tvp, @tenancy tvp, @result tvp out)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		declare	@ids I64Array;
		with cteSlip as
		(
			select	i.MatterID, Type=k.PostCourier, n.Number
			from	tvp.Triad#Slice(@slip, default, default)     x
			cross	apply loc.RefNbr#Cast(x.v1)                  m
			cross	apply loc.RefNbr#Cast(x.v2)                  n
			cross	apply core.RefNbr#Type()                     k
			cross	apply core.RefNbr#IdOfFirst(m.Number, k.MIT) i	
			join	shpt.Parcel#Raw()                            p on p.ID=i.MatterID
			where	p.RouteID in(select ID from tms.Route#Raw() where BrokerID=7004)
		)
		merge	into core._RefNbr as o using cteSlip as n
		on		(o.MatterID=n.MatterID and o.Type=n.Type)
		when	    matched and n.Number>N'' then update set o.Number=n.Number
		when	not matched	and n.Number>N'' then insert (  MatterID,   Type,   Number)
												  values (n.MatterID, n.Type, n.Number)
		output	inserted.MatterID into @ids;

		declare	@userID I32,    @roleID I32;
		select	@userID=UserID, @roleID=RoleID
		from	loc.Tenancy#Of(@tenancy);	

		declare	@actionID  I32=(select ImportHubManifest from core.Action#ID());
		declare	@spec core.TransitionSpec;
		insert	@spec select t.* from @ids
		cross	apply shpt.Parcel#Maybe(ID, @roleID, @actionID) t;
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID;
		
		declare	@exeSlip tvp;
		with cteStamp(Text) as
		(
			select	[text()]=concat(k.Many, i.MatterID, k.Triad, ToStateID, k.Triad
							 ,		dateadd(hour, -t.UtcOffset, x.v3), k.Trio, t.UtcOffset, k.Trio, t.ID)
			from	tvp.Triad#Slice(@slip, default, default) x		
			cross	apply core.MIC#IdOf(x.v1)                i
			join	@spec                                    s on s.MatterID=i.MatterID
			join	shpt.Parcel#Base()                       p on i.MatterID=p.ID
			join	core.Tenant#Raw()                        t on t.ID=p.RcvHubID
			cross	apply tvp.Spr#Const()                    k 
			for	xml path(N'')		
		)
		select	@exeSlip=Tvp from cteStamp cross apply tvp.Spr#Purify(text, default);
		execute core.RefStamp#Merge @slip=@exeSlip;

		select	@result=(select count(*) from @spec);

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END