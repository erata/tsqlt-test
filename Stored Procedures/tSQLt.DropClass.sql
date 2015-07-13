SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---Build+
CREATE PROCEDURE [tSQLt].[DropClass]
    @ClassName NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Cmd NVARCHAR(MAX);

    WITH ObjectInfo(name, type) AS
         (
           SELECT QUOTENAME(SCHEMA_NAME(O.schema_id))+'.'+QUOTENAME(O.name) , O.type
             FROM sys.objects AS O
            WHERE O.schema_id = SCHEMA_ID(@ClassName)
         ),
         TypeInfo(name) AS
         (
           SELECT QUOTENAME(SCHEMA_NAME(T.schema_id))+'.'+QUOTENAME(T.name)
             FROM sys.types AS T
            WHERE T.schema_id = SCHEMA_ID(@ClassName)
         ),
         DropStatements(no,cmd) AS
         (
           SELECT 10,
                  'DROP ' +
                  CASE type WHEN 'P' THEN 'PROCEDURE'
                            WHEN 'PC' THEN 'PROCEDURE'
                            WHEN 'U' THEN 'TABLE'
                            WHEN 'IF' THEN 'FUNCTION'
                            WHEN 'TF' THEN 'FUNCTION'
                            WHEN 'FN' THEN 'FUNCTION'
                            WHEN 'V' THEN 'VIEW'
                   END +
                   ' ' + 
                   name + 
                   ';'
              FROM ObjectInfo
             UNION ALL
           SELECT 20,
                  'DROP TYPE ' +
                   name + 
                   ';'
              FROM TypeInfo
             UNION ALL
            SELECT 10000,'DROP SCHEMA ' + QUOTENAME(name) +';'
              FROM sys.schemas
             WHERE schema_id = SCHEMA_ID(@ClassName)
         ),
         StatementBlob(xml)AS
         (
           SELECT cmd [text()]
             FROM DropStatements
            ORDER BY no
              FOR XML PATH(''), TYPE
         )
    SELECT @Cmd = xml.value('/', 'NVARCHAR(MAX)') 
      FROM StatementBlob;

    EXEC(@Cmd);
END;
---Build-
GO