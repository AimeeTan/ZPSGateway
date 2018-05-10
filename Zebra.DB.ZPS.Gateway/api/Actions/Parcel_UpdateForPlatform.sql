﻿/*
@slip    = Entry[Block<ParcelID, Duad<SvcType, Weight>,Duad<RefNbr, PreCourier>, Triad<ShprInfo, CneeInfo, IDInfo>, Many[Triad<SkuID, LineQty, LineTotal>]>]
*/
--Smile
CREATE PROCEDURE [api].[Parcel$UpdateForPlatform](@slip tvp, @tenancy tvp, @result tvp out)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;

		-- 0.	Contexts:
		declare	@roleID I32,    @userID I32,    @source tinyint;
		select	@roleID=RoleID, @userID=UserID, @source=p.Source
		from	loc.Tenancy#Of(@tenancy) x
		join	core.Party#Raw()         p on p.ID=x.UserID;

		declare	@idSeqs I64Seqs; insert @idSeqs(ID, Seq)
		select	t.v1, t.Seq
		from	tvp.Block#At(1, @slip, default, default)       x
		cross	apply tvp.Spr#Const()                          k
		cross	apply tvp.Field#Slice(x.Tvp, k.Entry, k.Entry) t

		--Parcel transist;
		declare	@actionID  I32=(select UpdateParcelInfo from core.Action#ID());
		declare	@spec core.TransitionSpec;
		insert	@spec select t.* from @idSeqs
		cross	apply shpt.Parcel#Tobe(ID, @roleID, @actionID) t;
		execute	core.Matter#TransitBySpec @spec=@spec, @userID=@userID;

		declare	@updatedSeqs I64Seqs;insert @updatedSeqs(ID, Seq)
		select	ID, x.Seq from @idSeqs x join @spec d on x.ID=d.MatterID;

	    if(exists(select * from @spec))
		begin
		--Merge RefNbr;		
		declare	@exeNbr tvp;
		with exeNbr(text) as
		(
			select	[text()]=concat(k.Many, x.Master, k.Triad, t.ClientRef, k.Triad, d.v1
							, k.Many, x.Master, k.Triad, t.PreCourier, k.Triad, d.v2)
			from	tvp.Block#FoldT(3, @updatedSeqs, @slip, default, default) x
			cross	apply tvp.Duad#Of(x.House, default)                       d
			cross	apply tvp.Spr#Const()                                     k
			cross	apply core.RefNbr#Type()                                  t
			for xml path(N'')
		)
		select	@exeNbr=Tvp from exeNbr cross apply tvp.Spr#Purify(text, default)  	
		execute	core.RefNbr#Merge @slip=@exeNbr;

		--Merge RefInfo:
		declare	@exeInfo tvp;
		with exeInfo(text) as
		(
			select	[text()]=concat(k.Many, x.Master, k.Triad, t.ShprInfo, k.Triad, d.v1
							, k.Many, x.Master, k.Triad, t.CneeInfo, k.Triad, d.v2
							, k.Many, x.Master, k.Triad, t.IDInfo, k.Triad, d.v3)
			from	tvp.Block#FoldT(4, @updatedSeqs, @slip, default, default) x
			cross	apply tvp.Triad#Of(x.House, default)                      d
			cross	apply tvp.Spr#Const()                                     k
			cross	apply core.RefInfo#Type()                                 t
			for xml path(N'')
		)
		select	@exeInfo=Tvp from exeInfo cross apply tvp.Spr#Purify(text, default)  	
		execute	core.RefInfo#Merge @slip=@exeInfo;

		--Merge BrkgInfo, DeclaredInfo
		with exeInfo(text) as
		(
			select	[text()]=concat(n.Many, x.Master, n.Triad, i.Type, n.Triad, i.Info)
			from	tvp.Block#FoldT(5, @updatedSeqs, @slip, default, default) x
			cross	apply tvp.Spr#Const()                                     n
			cross	apply
			(
			select	Type=k.DeclaredInfo,  s.Info
			from	core.RefInfo#Type()   k, invt.SkuInfo#ToDeclared(x.House) s	
			UNION	ALL
			select	Type=k.BrokerageInfo, b.Info
			from	tvp.Block#FoldT(2, @updatedSeqs, @slip, default, default) c 
			cross	apply tvp.Duad#Of(c.House, default)                       q
			join	core.Matter#Raw()                                         m on m.ID=x.Master
			cross	apply tms.SvcType#For(cast(q.v1 as int), m.PosterID)      t
			cross	apply tms.SvcRoute#For(t.ID, t.FallbackPOA)               o
			join	tms.Route#Raw()                                           d on d.ID=o.RouteID
			cross	apply invt.SkuInfo#ToBrokerage(x.House, d.BrokerID,  d.ClrMethodID) b
			cross	apply core.RefInfo#Type()                                 k                  
			where	x.Master=c.Master
			)                                                                 i
			
		)
		select	@exeInfo=Tvp from exeInfo cross apply tvp.Spr#Purify(text, default)  	
		execute	core.RefInfo#Merge @slip=@exeInfo;

		--update Parcel;
		with	cteParcel as
		(
			select	ParcelID=x.Master, SvcType=t.ID, Weight=cast(q.v2 as real)
			from	tvp.Block#FoldT(2, @updatedSeqs, @slip, default, default) x
			cross	apply tvp.Duad#Of(x.House, default)                       q
			join	core.Matter#Raw()                                         m on m.ID=x.Master
			join	core.Party#Raw()                                          r on r.ID=m.PosterID
			cross	apply tms.SvcType#For(cast(q.v1 as int), r.PID)           t
		)
		update o set SvcType=n.SvcType , Weight =n.Weight from shpt._Parcel o join cteParcel n on o.ID=n.ParcelID
		end

		;with cteResult(text) as
		(
			select	[text()]=concat(s.Many, a.Number, s.Duad, isnull(u.ID, 0))   
			from	@idSeqs                   x
			cross	apply core.RefNbr#Type()  k
			join	core.RefNbr#Raw()         a on a.Type=k.MIT and a.MatterID=x.ID
			cross	apply tvp.Spr#Const()     s
			left	join @updatedSeqs         u on x.ID=u.ID
			for xml path(N'')
		)
		select	@result=Tvp from cteResult cross apply tvp.Spr#Purify(text, default);	
		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
