USE [DMHub]
GO
/****** Object:  StoredProcedure [USJBA].[ASNExport]    Script Date: 5/24/2019 1:17:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Carsten Bredsdorff
-- Create date: Apr 30, 2019
-- Description:	Creates JBA ASN XML File Info related to POs 
-- Change History: 
-- =============================================
ALTER PROCEDURE [USJBA].[ASNExport] 
	-- Add the parameters for the stored procedure here
	@itemID int
AS

BEGIN

	--declare @itemId int = 302704 

	DECLARE @now DATETIME = GETDATE()
	DECLARE @nowString VARCHAR(14)
	SELECT @nowstring = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(20), @now, 120),'-',''), ':',''),' ','')
		
	DECLARE @xmlContent XML, @ASNID VARCHAR(20)
	SELECT @ASNID = [filename], @xmlContent = xmlcontent FROM [system].[item] WHERE ID = @itemID

	
	--DECLARE @POSO TABLE (POSOpoNumber NVARCHAR(100), POSOSalesOrder NVARCHAR(100))

	--INSERT INTO @POSO
	--SELECT PURCHASEORDERNUMBER, 
	--CASE WHEN ph.hdmInterCompanyOrder = 0 and ph.HDMINTERCOMPANYORIGINALSALESID <> '' THEN ph.HDMINTERCOMPANYORIGINALSALESID ELSE '' END 
	--FROM [ENTITYSTORE].[PurchPurchaseOrderHeaderV2] ph
	--WHERE PURCHASEORDERNUMBER in (SELECT DISTINCT rtrim(PARSENAME(replace(XMIT_PO, '-','.'), 2)) 
	--FROM [AWX].[ASNDetails] WHERE ASNID = @ASNID)

	--IF ((SELECT SUM(1) FROM @POSO) is null)
	--BEGIN
	--	--transfer Orders / non intercompany
	--	INSERT INTO @POSO
	--	SELECT DISTINCT RTRIM(PARSENAME(REPLACE(XMIT_PO, '-','.'), 2)), null 
	--	FROM [AWX].[ASNDetails] 
	--	WHERE ASNID = @ASNID
	--END


--#####################################################################
--# Build Base Data Sets to be used when building XML
--#
--#####################################################################
							
	--drop all temp tables if exist
	IF OBJECT_ID('tempdb..#shipment') IS NOT NULL DROP TABLE #shipment
	IF OBJECT_ID('tempdb..#orders') IS NOT NULL DROP TABLE #orders
	IF OBJECT_ID('tempdb..#item') IS NOT NULL DROP TABLE #item
	IF OBJECT_ID('tempdb..#pack') IS NOT NULL DROP TABLE #pack


	SELECT 
		shipment.record.value('(MailboxID)[1]','nvarchar(100)') as MailboxID,
		shipment.record.value('(MailboxDate)[1]','nvarchar(100)') as MailboxDate,
		shipment.record.value('(TradingPartnerID)[1]','nvarchar(100)') as TradingPartnerID,
		shipment.record.value('(ASNID)[1]','nvarchar(100)') as ASNID,
		shipment.record.value('(TransportationTypeCode)[1]','nvarchar(100)') as TransportationTypeCode,
		shipment.record.value('(BillOfLading)[1]','nvarchar(100)') as BillOfLading,
		shipment.record.value('(EquipmentTypeCode)[1]','nvarchar(100)') as EquipmentTypeCode,
		shipment.record.value('(EquipmentNumber)[1]','nvarchar(100)') as EquipmentNumber,
		shipment.record.value('(SealNumber)[1]','nvarchar(100)') as SealNumber,
		shipment.record.value('(TotalCartons)[1]','nvarchar(100)') as TotalCartons,
		shipment.record.value('(ShipmentWeight)[1]','nvarchar(100)') as ShipmentWeight,
		shipment.record.value('(ShipmentWgtUOM)[1]','nvarchar(100)') as ShipmentWgtUOM,
		shipment.record.value('(SH_Name)[1]','nvarchar(100)') as SH_Name,
		shipment.record.value('(SH_Addr1)[1]','nvarchar(100)') as SH_Addr1,
		shipment.record.value('(SH_Addr2)[1]','nvarchar(100)') as SH_Addr2,
		shipment.record.value('(SH_Addr3)[1]','nvarchar(100)') as SH_Addr3,
		shipment.record.value('(SH_Addr4)[1]','nvarchar(100)') as SH_Addr4,
		shipment.record.value('(SH_Addr5)[1]','nvarchar(100)') as SH_Addr5,
		shipment.record.value('(ST_Name)[1]','nvarchar(100)') as ST_Name,
		shipment.record.value('(ST_Addr1)[1]','nvarchar(100)') as ST_Addr1,
		shipment.record.value('(ST_Addr2)[1]','nvarchar(100)') as ST_Addr2,
		shipment.record.value('(ST_Addr5)[1]','nvarchar(100)') as ST_Addr5,
		shipment.record.value('(ST_Post)[1]','nvarchar(100)') as ST_Post,
		shipment.record.value('(ASNDate)[1]','datetime') as ASNDate,
		shipment.record.value('(ShipDt)[1]','datetime') as ShipDt,
		shipment.record.value('(ArrvDt)[1]','datetime') as ArrvDt
	INTO #shipment
	FROM @xmlContent.nodes('Shipment') AS shipment(record)

	
	SELECT 
		orders.record.value('(../ASNID)[1]','nvarchar(100)') as PREADVICE,
		--orders.record.value('(../ArrvDt)[1]','datetime') AS DELDATE,
		orders.record.value('(../TradingPartnerID)[1]','nvarchar(100)') AS SUPPLIER_ID,
		orders.record.value('(MailboxID)[1]','nvarchar(100)') as MailboxID,
		orders.record.value('(PONumber)[1]','nvarchar(100)') as PONumber,
		orders.record.value('(SupplierOrderRef)[1]','nvarchar(100)') as SupplierOrderRef,
		orders.record.value('(XMIT_PO)[1]','nvarchar(100)') as XMIT_PO,
		orders.record.value('(PackingList)[1]','nvarchar(100)') as PackingList,
		orders.record.value('(DistributorPO)[1]','nvarchar(100)') as DistributorPO,
		orders.record.value('(DistributorCode)[1]','nvarchar(100)') as DistributorCode,
		orders.record.value('(dftReceivingWarehouseID)[1]','nvarchar(100)') as dftReceivingWarehouseID,
		orders.record.value('(dftReceivingSiteID)[1]','nvarchar(100)') as dftReceivingSiteID,
		orders.record.value('(InterCompanyCustAccount)[1]','nvarchar(100)') as InterCompanyCustAccount,
		orders.record.value('(InterCompanySalesOrderID)[1]','nvarchar(100)') as InterCompanySalesOrderID,
		orders.record.value('(DistCustNum)[1]','nvarchar(100)') as DistCustNum,
		orders.record.value('(DistCustPO)[1]','nvarchar(100)') as DistCustPO
	INTO #orders
	FROM @xmlContent.nodes('Shipment/Order') AS orders(record)

	SELECT
		pack.record.value('(MailboxID)[1]','nvarchar(100)') as MailboxID,
		pack.record.value('(CartonID)[1]','nvarchar(100)') as CartonID,
		pack.record.value('(PackagingCode)[1]','nvarchar(100)') as PackagingCode,
		pack.record.value('(CtnWgt)[1]','nvarchar(100)') as CtnWgt,
		pack.record.value('(CtnWgtUOM)[1]','nvarchar(100)') as CtnWgtUOM,
		pack.record.value('(CtnVol)[1]','nvarchar(100)') as CtnVol,
		pack.record.value('(CtnVolUOM)[1]','nvarchar(100)') as CtnVolUOM,
		pack.record.value('(PackingList)[1]','nvarchar(100)') as PackingList,
		pack.record.value('(PONumber)[1]','nvarchar(100)') as PONumber
	INTO #pack
	FROM @xmlContent.nodes('Shipment/Order/Pack') AS pack(record)

	SELECT
		item.record.value('(../PackingList)[1]','nvarchar(100)') as PackingList,
		item.record.value('(MailboxID)[1]','nvarchar(100)') as MailboxID,
		item.record.value('(PONumber)[1]','nvarchar(100)') as PONumber,
		item.record.value('(CartonID)[1]','nvarchar(100)') as CartonID,
		item.record.value('(Barcode)[1]','nvarchar(100)') as Barcode,
		item.record.value('(QtyShipped)[1]','decimal(18,2)') as QtyShipped,
		item.record.value('(QtyUOM)[1]','nvarchar(100)') as QtyUOM,
		item.record.value('(ProductCode)[1]','nvarchar(100)') as ProductCode,
		item.record.value('(SizeCode)[1]','nvarchar(100)') as SizeCode
	INTO #item
	FROM  @xmlContent.nodes('Shipment/Order/Pack/Item') AS item(record)

	--select * from #item

----#####################################################################
----# Build ASN XML
----#
----#####################################################################


DECLARE @exportString NVARCHAR(MAX)

SELECT @exportString = N'<?xml version="1.0" encoding="UTF-8"?>' + 
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
				MailboxID,
				MailboxDate,
				TradingPartnerID,
				ASNID,
				TransportationTypeCode,
				BillOfLading,
				EquipmentTypeCode,
				EquipmentNumber,
				SealNumber,
				TotalCartons,
				ShipmentWeight,
				ShipmentWgtUOM,
				SH_Name,
				SH_Addr1,
				SH_Addr2,
				SH_Addr3,
				SH_Addr4,
				SH_Addr5,
				ST_Name,
				ST_Addr1,
				ST_Addr2,
				ST_Addr5,
				ST_Post,
				ASNDate,
				ShipDt,
				ArrvDt,
				CAST ((
					SELECT
						o.MailboxID,
						o.PONumber,
						SupplierOrderRef,
						XMIT_PO,
						o.PackingList,
						DistributorPO,
						DistributorCode,
						dftReceivingWarehouseID,
						dftReceivingSiteID,
						InterCompanyCustAccount,
						InterCompanySalesOrderID,
						DistCustNum,
						DistCustPO,
						CAST ((
							SELECT
								MailboxID,
								CartonID,
								PackagingCode,
								CtnWgt,
								CtnWgtUOM,
								CtnVol,
								CtnVolUOM,
								PackingList,
								PONumber,
								CAST ((
									SELECT
										i.MailboxID,
										i.PackingList,
										i.PONumber,
										i.CartonID,
										i.Barcode,
										i.QtyShipped,
										i.QtyUOM,
										i.ProductCode,
										i.SizeCode
									FROM #item i
									WHERE i.MailboxID = p.MailboxID AND i.CartonID = p.CartonID AND i.PONumber = p.PONumber
									FOR XML PATH('Item')) AS XML)
								FROM #pack p
								WHERE p.MailboxID = o.MailboxID and p.PONumber = o.PONumber
								FOR XML PATH('Pack')) AS XML)
						FROM #orders o
						WHERE o.MailboxID = s.MailboxID 
						FOR XML PATH('Order')) AS XML)
					FROM #shipment s
					FOR XML PATH('Shipment')) AS XML)
					FOR XML PATH('Purord')) AS NVARCHAR(MAX))

	----Cleanup tempdb tables
	IF OBJECT_ID('tempdb..#shipment') IS NOT NULL DROP TABLE #shipment
	IF OBJECT_ID('tempdb..#orders') IS NOT NULL DROP TABLE #orders
	IF OBJECT_ID('tempdb..#item') IS NOT NULL DROP TABLE #item
	IF OBJECT_ID('tempdb..#pack') IS NOT NULL DROP TABLE #pack

	select @exportString


END



