-- Eason
CREATE PROCEDURE [svc].[Setting$Update](@name tvp, @value tvp)

-- WITH ENCRYPTION
AS BEGIN
	update	core._Setting
	set		Value=@value
	where	Name=@name
END