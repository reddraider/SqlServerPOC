USE [DMHub]
GO
/****** Object:  StoredProcedure [HUB].[ASNSplit]    Script Date: 5/24/2019 1:15:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Carsten Bredsdorff
-- Create date: 4/26/2019
-- Description:	Will split ASN data into destination specific system.item rows (JBA or NRI) 
-- =============================================
ALTER PROCEDURE [HUB].[ASNSplit]
	-- Add the parameters for the stored procedure here
	@itemID int
AS
BEGIN
	SET NOCOUNT ON;

	--declare @itemId int = 297435

	DECLARE @xmlContent XML, @filePath VARCHAR(50)
	SELECT @filePath = filepath, @xmlContent = xmlContent--CAST(REPLACE(fileContent,'<?xml version="1.0" encoding="utf-8"?>','<?xml version="1.0" encoding="utf-16"?>') AS XML)
		FROM [system].[item] 
		WHERE ID = @itemID
	
	DECLARE @type VARCHAR(50)
	DECLARE @ActualError_Message AS VARCHAR(2000)
	DECLARE @ActualError_State INT
	
	DECLARE @ReceivingWarehouse VARCHAR(50)

	SELECT @ReceivingWarehouse = @xmlContent.value('Shipment[1]/Order[1]/dftReceivingWarehouseID[1]','varchar(50)')

	SELECT @type = CASE @ReceivingWarehouse
			WHEN 'USB2B01' THEN 'USJBA.ASNPO'
			WHEN 'CAB2B01' THEN 'NRI.ASNPO'
			WHEN '201-DD' THEN '201-DD.ASN'
			WHEN '242-DD' THEN '242-DD.ASN'
			ELSE 'NOT NA BOUND'
			END

	IF(@type <> 'NOT NA BOUND')
		BEGIN
		INSERT INTO [system].[item]
				([type]
				,[filePath]
				,[fileName]
				,[fileType]
				,[fileContent]
				,[xmlContent]
				,[status]
				,[importDate]
				,[importedUsing]
				,[parentID]
				,[itemNumber]
				)
				SELECT   @type AS [type]
						,@filePath as [filepath]
						,line.record.value('ASNID[1]','nvarchar(50)') AS 'fileName'
						,CASE 
							WHEN @type = 'USJBA.ASNPO' THEN 'XML'
							WHEN @type = 'NRI.ASNPO' THEN 'CSV'
							WHEN @type = '201-DD.ASN' THEN 'XXX'
							WHEN @type =  '242-DD.ASN' THEN 'XXX'
							ELSE '' END AS fileType
						,null as fileContent
						,record.query('.')  AS xmlContent
						,'000' 
						,getdate() AS importDate
						,'HUB.IN_856.EDI' AS importedUsing 
						,@itemId AS parentID
						,row_number() OVER(ORDER BY line.record) as itemNumber
				FROM @xmlContent.nodes('Shipment') as line(record)
			END
		ELSE
			BEGIN
				update [system].[item] set [type] = @type where id = @itemId
			END
		--ELSE
		--	BEGIN
		--		SELECT @ActualError_Message = ERROR_MESSAGE(), @ActualError_State = ISNULL(ERROR_STATE(), 1)
		--		RAISERROR ('ASN Type Incorrect', 11, @ActualError_State)
		--	END

	--update [system].[item] set status = 899 where id = @itemId
END
