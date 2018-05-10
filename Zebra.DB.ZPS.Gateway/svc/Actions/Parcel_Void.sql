/*
@slip    tvp=Comma[ParcelID]
@result  tvp=Many[Duad<UnVoidID, ClientRefNbr>]
*/
--Smile
CREATE PROCEDURE [svc].[Parcel$Void](@slip tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET	XACT_ABORT ON;
	BEGIN TRY
		BEGIN TRAN;
	    
		declare	@userID I32,    @roleID I32,    @actionID I32;
		select	@userID=UserID, @roleID=RoleID, @actionID=VoidParcel
		from	loc.Tenancy#Of(@tenancy), core.Action#ID();

		--	1.Parcel Transit
		declare	@spec core.TransitionSpec;
		insert	@spec select t.* 
		from	tvp.I64#Slice(@slip) x
		cross	apply shpt.Parcel#Tobe(x.ID, @roleID, @actionID) t;
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID;

		declare	@clientRef E8=(select ClientRef from core.RefNbr#Type());
		declare	@voidInfo  E8=(select VoidInfo  from core.RefInfo#Type());
		--	2.  Insert VoidInfo
		with cteVoidInfo as
		(
			select	r.MatterID, Info=Number
			from	@spec                    x
			join	core.RefNbr#Raw()        r on r.MatterID=x.MatterID and r.Type=@clientRef
		)
		insert	into core._RefInfo(MatterID, Type,      Info)
		select					   MatterID, @voidInfo, Info
		from	cteVoidInfo;

		-- 3.	delete ClientRefNbr		
		delete	from core._RefNbr 
		where	Type=@clientRef	and MatterID in (select MatterID from @spec)
		;

		with cteResult(text) as
		(

			select	[text()]=concat(k.Many, x.ID, k.Duad, c.Number)
			from	tvp.I64#Slice(@slip)  x
			join	core.RefNbr#Raw()     c on c.MatterID=x.ID and c.Type=@clientRef
			cross	apply tvp.Spr#Const() k
			where	not exists(select MatterID from @spec where MatterID=x.ID)
			for		xml path(N'')
		)
		select	@result=Tvp from cteResult cross apply tvp.Spr#Purify(text, default)  
		;
	
		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END