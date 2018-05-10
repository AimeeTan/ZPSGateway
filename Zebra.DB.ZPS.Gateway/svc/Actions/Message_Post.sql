/*
@slip    = MatterID
@context = Duad<Body, (Message==0, BoundStage!=0)>
*/
--PeterHo: HACK!!! (Matter Only)
CREATE PROCEDURE [svc].[Message$Post](@slip tvp, @context tvp, @tenancy tvp)
--WITH ENCRYPTION--
AS
BEGIN
	SET	NOCOUNT ON;

	declare	@body msg, @boundStage E32;
	select	@body=v1,  @boundStage=v2
	from	tvp.Duad#Of(@context, default);

	if (@boundStage>0) begin
		declare	@auxID   E32=(select Instruction from core.Challenge#Type());
		declare	@exeSlip tvp=(select Tvp from tvp.Triad#Make(/*rowID*/@slip, @auxID, @boundStage));
		execute core.Challenge#Push @slip=@exeSlip, @context=@body, @tenancy=@tenancy;
	end
	else begin
		declare	@rowAuxes I64Enums;
		insert	@rowAuxes (ID, Val) select ID, 0 from tvp.I64#Slice(@slip);
		
		declare	@regID I32=(select Matter from core.Registry#ID());
		execute	core.Message#Invoke @regID=@regID, @rowAuxes=@rowAuxes, @body=@body, @tenancy=@tenancy;
	end
END