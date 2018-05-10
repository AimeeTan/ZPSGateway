CREATE TYPE [dbo].[I64TrioAmts] AS TABLE(
	[LID] [dbo].[I64] NOT NULL,
	[MID] [dbo].[I64] NOT NULL,
	[RID] [dbo].[I64] NOT NULL,
	[Amt] [dbo].[amt] NOT NULL,
	PRIMARY KEY CLUSTERED 
(
	[LID] ASC,
	[MID] ASC,
	[RID] ASC,
	[Amt] ASC
)WITH (IGNORE_DUP_KEY = OFF)
)