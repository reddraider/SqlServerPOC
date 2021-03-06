USE [DMHub]
GO
/****** Object:  StoredProcedure [USJBA].[PO]    Script Date: 5/24/2019 1:16:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [USJBA].[PO] 
	-- Add the parameters for the stored procedure here
	@itemID int
AS

--declare @itemId int = 3303

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @ERROR NVARCHAR(MAX)
	declare @xmlContent as xml
	declare @filePath as nvarchar(1000)
	declare @fileName as nvarchar(1000)
	declare @exportSQL as nvarchar(1000)
	declare @now datetime
	select @now = importdate from [system].[item] with (nolock) where id = @itemID
	declare @nowString varchar(14)
	select @nowstring = replace(replace(replace(convert(varchar(20), @now, 120),'-',''), ':',''),' ','')

	declare @type varchar(100)

	SELECT @type = [type] from system.item where id = @itemID

	declare @data xml
	declare @id int

	set @fileName = 'PurchaseOrder-'+cast(@itemId as varchar(10))+'-' + @nowString
	--set @fileName = '3PL.PURCHASEORDER-'+cast(@itemId as varchar(10))+'-' + @nowString
	set @filePath = N'\\aw10-ad2008-2\airwair\hubtest\usjba\export\'+@fileName+'.xml'
	
	IF @type = '3PL.PURCHASEORDER.USJBA' --standard PO without ASN
	BEGIN
		set @exportSQL = N'EXEC [DMHUB].[USJBA].[POExport] ' + CAST(@itemId as Nvarchar(10))
	END
	ELSE
	BEGIN -- ASN PO data
		set @exportSQL = N'EXEC [DMHUB].[USJBA].[ASNExport] ' + CAST(@itemId as Nvarchar(10))
	END

	EXECUTE [system].[ExportData] 
		@itemId
		,@filePath
		,@exportSQL
		,1
		,0
		,N','

	Set @data = ' <data>
	<fileList>
	<file>
		<fileName>'+@filePath+'</fileName>
		<uploadPath>FromHub/</uploadPath>
		<remoteFileName>'+@fileName+'.txt</remoteFileName>
		<renameFileName>'+@fileName+'.xml</renameFileName>
	</file>
	</fileList>
</data>'


	EXECUTE [system].[CallCommunicator] @itemId,@data, N'USJBA.UPLOAD'
END
