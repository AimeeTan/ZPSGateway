/*
@slip   =Many[Triad<TrackingNbr, PostCourier, CourierCode>]
*/
--Smile
CREATE PROCEDURE [svc].[Parcel$MergePostCourier](@slip tvp, @tenancy tvp)
WITH ENCRYPTION
AS
BEGIN
	SET	NOCOUNT    ON;
	SET XACT_ABORT ON;
	BEGIN TRY
		BEGIN	TRAN;
	
		declare	@type E8=(select PostCourier from core.RefNbr#Type());
		
		declare	@parcelCourierIDs dbo.I64Pairs;
		with cteCourierNbr as
		(
			select	m.MatterID, Number=cast(v2 as varchar(40)), CourierID
			from	tvp.Triad#Slice(@slip, default, default) x
			cross	apply core.RefNbr#ScanOne(x.v1, default, default) m
			cross	apply tms.Courier#IdOfAlias(v3) t
		)
		merge	core._RefNbr as r using cteCourierNbr as n
		on		(r.MatterID=n.MatterID and r.Type=@type)
		when	matched     and n.Number=N'' then delete
		when	matched     and n.Number>N'' then update set r.Number=n.Number
		when	not matched and n.Number>N'' then insert(MatterID,  Type,   Number)
												values(n.MatterID, @type, n.Number)
		output inserted.MatterID, n.CourierID into @parcelCourierIDs;

		update o set o.LastMilerID=n.RID from shpt._Parcel o join @parcelCourierIDs n on o.ID=n.LID;

		COMMIT	TRAN;
	END TRY
	BEGIN CATCH
		if (xact_state() = -1) ROLLBACK TRAN; throw;
	END CATCH
END
