USE [DMHub]
GO
/****** Object:  StoredProcedure [USJBA].[POExport]    Script Date: 5/24/2019 1:16:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Carsten Bredsdorff
-- Create date: May 10, 2019
-- Description:	Will create USJBA POExport for those suppliers that don't provide ASN data.
-- =============================================
ALTER PROCEDURE [USJBA].[POExport]
	-- Add the parameters for the stored procedure here
	@itemId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
/*
	Create in the same structure as the ASN from the factory, enriched with 201 PO/SO data, using the same node names
	<Shipment>
		<Order>
			(no Pack)
			<Item>
*/

	--declare @itemid int = 3303

	DECLARE @now DATETIME = GETDATE()
	DECLARE @nowString VARCHAR(14)
	SELECT @nowstring = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(20), @now, 120),'-',''), ':',''),' ','')

	DECLARE @data NVARCHAR(MAX)
	DECLARE @xmlContent XML
	SELECT @xmlContent = xmlContent FROM [system].[item] WHERE ID = @itemId

	declare @PoNumber varchar(50)

	select @PoNumber = [filename] from system.item where id = @itemId

SELECT @data = N'<?xml version="1.0" encoding="UTF-8"?>' + 
	 CAST((
		SELECT CAST((
		SELECT
			'PURORD' as InterfaceName,
			RIGHT('0000000000000' + cast(@itemID AS VARCHAR(13)), 13) AS InterChangeID,
			@nowString as TransferDTstamp
		FOR XML PATH('InterchangeSection')
		) AS XML),
		 CAST((
			 SELECT
				'' AS MailboxID,
				'' AS MailboxDate,
				'' AS TradingPartnerID,
				'' AS ASNID,
				'' AS TransportationTypeCode,
				'' AS BillOfLading,
				'' AS EquipmentTypeCode,
				'' AS EquipmentNumber,
				'' AS SealNumber,
				'' AS TotalCartons,
				'' AS ShipmentWeight,
				'' AS ShipmentWgtUOM,
				'' AS SH_Name,
				'' AS SH_Addr1,
				'' AS SH_Addr2,
				'' AS SH_Addr3,
				'' AS SH_Addr4,
				'' AS SH_Addr5,
				'' AS ST_Name,
				'' AS ST_Addr1,
				'' AS ST_Addr2,
				'' AS ST_Addr5,
				'' AS ST_Post,
				'' AS ASNDate,
				'' AS ShipDt,
				po.shipment.value('DELDATE[1]','varchar(10)') AS ArrvDt,
				CAST ((
					SELECT
						'' AS MailboxID,
						@PoNumber AS PONumber,
						'' AS SupplierOrderRef,
						'' AS XMIT_PO,
						'' AS PackingList,
						RTRIM(LTRIM(isnull(soh.CUSTOMERSORDERREFERENCE,''))) as DistributorPO,
						'' AS DistributorCode,
						isnull(poh.DEFAULTRECEIVINGWAREHOUSEID,'') as dftReceivingWarehouseID,
						isnull(poh.DEFAULTRECEIVINGSITEID,'') as dftReceivingSiteID,
						isnull(poh.HDMINTERCOMPANYORIGINALCUSTACCOUNT,'') as InterCompanyCustAccount, --will exist if subsidiary order
						isnull(poh.HDMINTERCOMPANYORIGINALSALESID,'') as InterCompanySalesOrderID, --will exist if subsidiary order
						'TBD' AS DistCustNum,
						'TBD' AS DistCustPO,
							CAST ((
								SELECT
									'' AS MailboxID,
									@PoNumber AS PONumber,
									@PoNumber AS PackingList,
									'' AS CartonID,
									po.lines.value('BARCODE[1]','varchar(80)') AS Barcode,
									po.lines.value('QUANTITY[1]','decimal(18,0)') AS QtyShipped,
									'' AS QtyUOM,
									po.lines.value('STYLE[1]','varchar(20)') AS ProductCode,
									po.lines.value('ProductSizeId[1]','varchar(10)') AS SizeCode
								FROM @XmlContent.nodes('PurchaseHeader/PurchaseOrderLine') as po(lines)
							FOR XML PATH('Item')) AS XML)
						FROM @XmlContent.nodes('PurchaseHeader') as po(orders)
						LEFT JOIN [ENTITYSTORE].[PurchPurchaseOrderHeaderV2] POH ON POH.[PURCHASEORDERNUMBER] = @PoNumber
						LEFT JOIN [ENTITYSTORE].[SalesOrderHeaderV2] SOH ON POH.HDMINTERCOMPANYORIGINALSALESID=SOH.SALESORDERNUMBER
						FOR XML PATH('Order')) AS XML)
					FROM @XmlContent.nodes('PurchaseHeader/PurchaseOrderLine') as po(shipment)
					FOR XML PATH('Shipment')) AS XML)
			FOR XML PATH('Purord')) AS NVARCHAR(MAX))

			
			SELECT @data

--SELECT @data = N'<?xml version="1.0" encoding="UTF-8"?>' + 
--		 CAST((
--			SELECT	CAST((
--				SELECT 
--				'PURORD' as InterfaceName,
--				RIGHT('0000000000000' + cast(@itemID AS VARCHAR(13)), 13) AS InterChangeID,
--				@nowString as TransferDTstamp
--				FOR XML PATH('InterchangeSection')
--			) AS XML),

--			CAST((			
--					SELECT 
--						'201' AS COMPANY,
--						'USB2B01' AS LOCATIONID,
--						'' AS PREADVICE, --ASN
--						'' AS SUPPLIER_ID,
--					CAST((
--							SELECT

--								'' AS SALESORDERID,
--								'' as [STATUS],
--								'' as JBACOMPANY,
--								'' as JBAORDER,
--								0 as JBALINE,
--								'' as ERROR,
--								0 as RECEIVED,
--							CAST((
--								SELECT 
--									'' AS CARTONID, 
--									'' AS QUANTITY
--								FOR XML PATH('CARTON'), ROOT('CARTONS')) AS XML)
--							FROM @XmlContent.nodes('PurchaseHeader/PurchaseOrderLine') as po(lines)
--							FOR XML PATH('ContainerLine')) AS XML)
--				FROM @XmlContent.nodes('PurchaseHeader') AS po(header)
--				FOR XML PATH('ContainerHeader')) AS XML)
--			FOR XML PATH('Purord')) AS NVARCHAR(MAX))


	
END
