
CREATE PROCEDURE DBO.SP_SEARCHCOLUMN   
(  
	@COLUMNNAME SYSNAME  
	, @CURRENTDB INT = 0  
	, @TEMPTABLE VARCHAR(200) = NULL  
)  
AS  
BEGIN 
 
	SET NOCOUNT ON  
   
	DECLARE 
		@STRQUERY VARCHAR(1000)  
		, @CRLF CHAR(2)  
		, @CTMAX INT  
		, @DBNAME SYSNAME  
  
	SELECT  @CRLF   = CHAR(13) + CHAR(10)  
  
	EXEC SP_DROPOBJECT #RESULTS   
	CREATE TABLE #RESULTS (DBNAME VARCHAR(30), XTYPE VARCHAR(2), OBJECTNAME SYSNAME, COLUMNNAME SYSNAME)  
  
	IF @CURRENTDB = 1  
	BEGIN  
  
		SELECT @STRQUERY = 'SELECT DB_NAME(), O.XTYPE, O.NAME, C.NAME ' + @CRLF +  
		'FROM SYSOBJECTS O ' + @CRLF +  
		'INNER JOIN SYSCOLUMNS C ON O.ID = C.ID ' + @CRLF +  
		'WHERE C.NAME LIKE ''' + @COLUMNNAME + ''''  
  
		--   INSERT INTO #RESULTS  
		--   EXEC(@STRQUERY)  

		SET @STRQUERY = 'INSERT INTO #RESULTS ' + @STRQUERY
		EXEC (@STRQUERY)

	END  
	ELSE  
	BEGIN  
		EXEC SP_DROPOBJECT #DATABASES  
  
		SELECT ROWID = IDENTITY(INT,1,1), DBNAME = NAME  
		INTO #DATABASES  
		FROM MASTER..SYSDATABASES  
  
		SELECT @CTMAX = MAX(ROWID) FROM #DATABASES  
  
		WHILE @CTMAX > 0  
		BEGIN  
			SELECT @STRQUERY = 'SELECT ''' + DBNAME + ''', O.XTYPE, O.NAME, C.NAME ' + @CRLF +  
			'FROM [' + DBNAME + ']..SYSOBJECTS O ' + @CRLF +  
			'INNER JOIN [' + DBNAME + ']..SYSCOLUMNS C ON O.ID = C.ID ' + @CRLF +  
			'WHERE C.NAME LIKE ''' + @COLUMNNAME + ''''  
			FROM #DATABASES   
			WHERE ROWID = @CTMAX  
  
			--     INSERT INTO #RESULTS  
			--     EXEC(@STRQUERY)  
			SET @STRQUERY = 'INSERT INTO #RESULTS ' + @STRQUERY
			EXEC (@STRQUERY)
  
			SELECT @CTMAX = @CTMAX - 1  
		END  
  
	END  
  
	IF @TEMPTABLE IS NULL  
	BEGIN  
		SELECT DBNAME, XTYPE, OBJECTNAME, COLUMNNAME  
		FROM #RESULTS   
		ORDER BY DBNAME, XTYPE, OBJECTNAME, COLUMNNAME  
	END  
	ELSE  
	BEGIN  
		DECLARE @INSERTSQL VARCHAR(8000)  
		SELECT @INSERTSQL =  
		'  
		INSERT '+ @TEMPTABLE +' ( DBNAME, XTYPE, OBJECTNAME, COLUMNNAME )   
		SELECT DBNAME, XTYPE, OBJECTNAME, COLUMNNAME  
		FROM #RESULTS   
		ORDER BY DBNAME, XTYPE, OBJECTNAME, COLUMNNAME  
		'  
		EXEC (@INSERTSQL)  

	END  
  
END  
  

