alter PROCEDURE [dbo].[cbInvUploadSelectDataForADV]
	(
		@Id int
	)
AS
BEGIN
	DECLARE @botOIId int
	SELECT
		@botOIId = Id
		FROM tBusinessObjectType bot
		WHERE bot.Name = 'OrderItem'
	DECLARE @rsLocalId int
	SELECT
		@rsLocalId = Id
		FROM tRemoteSystem rs
		WHERE rs.Code = 'LOCAL'

	SELECT
		qid.VIN									AS [Ref Number],
		ncbd.DocumentDate						AS [Ref Date],
		qi.KreditorCode							AS [Dealer],
		qi.InvoiceNo							AS [Dealer Invoice],
		q.serviceDate							AS [Delivery Date],
		q.ShipToCode							AS [Workshop],
		qil.AuthorisationCode					AS [P/O Number],
		qit.MP_ItemSequence						AS [P/O Line],
		CAST(qid.Code AS varchar(20))			AS [Part Number],
		CAST(qid.Description AS varchar(80))	AS [Description],
		CASE WHEN qi.InvoiceType = 'D'
			THEN qit.quantity
			ELSE -qit.quantity
		END										AS [Quantity],
		CASE WHEN oi.InvoicingTypeId = 0
			THEN
				oi.RetailPrice * oi.Quantity
			ELSE
				-oi.RetailPrice * oi.Quantity
			END
												AS [RRP Net Value],
		CASE WHEN oi.InvoicingTypeId = 0
			THEN
				oi.RetailPrice * oi.Quantity * (1 + oi.TaxRate * .01)
			ELSE
				-oi.RetailPrice * oi.Quantity * (1 + oi.TaxRate * .01)
			END
												AS [RRP Gross Value],
		CASE WHEN oi.InvoicingTypeId = 0  
   THEN  
    oi.TotalPrice
   ELSE  
    -oi.TotalPrice  
   END  
            AS [Advantage Price Net Value],  
  CASE WHEN oi.InvoicingTypeId = 0  
   THEN  
    oi.TotalPrice * 0.2 
   ELSE  
    -oi.TotalPrice * 0.2   
   END  
            AS [Advantage Price Vat Value],  
  CASE WHEN oi.InvoicingTypeId = 0  
   THEN  
    (oi.TotalPrice +(oi.TotalPrice * 0.2))
   ELSE  
     -(oi.TotalPrice +(oi.TotalPrice * 0.2)) 
   END  
            AS [Advantage Price Gross Value],  
  CASE WHEN oi.InvoicingTypeId = 0  
   THEN  
    oid.PriceExclTax 
   ELSE  
    -oid.PriceExclTax 
   END  
            AS [Dealer Net Price],  
  CASE WHEN oi.InvoicingTypeId = 0  
   THEN  
    oid.PriceExclTax * oid.TaxRate * .01  
   ELSE  
    -oid.PriceExclTax * oid.TaxRate * .01  
   END  
            AS [Dealer Price Vat Value],  
  CASE WHEN oi.InvoicingTypeId = 0  
   THEN  
    ((oid.PriceExclTax )+(oid.PriceExclTax * oid.TaxRate * .01 ))
   ELSE  
    ((-oid.PriceExclTax )+(oid.PriceExclTax * oid.TaxRate * .01))
   END  
            AS [Dealer Price Gross Value],
    
  ISNULL((  
   SELECT TOP 1  
    rsh.InvoiceNumber   
    FROM tRemoteObjectMapper romItem  
     JOIN tOrderItem oi ON (romItem.LocalRowId = oi.Id)  
      AND (oi.InvoicingTypeId <> 0)  
     JOIN tOrderItem roi ON (roi.Id = oi.RelatedOrderItemId)  
     JOIN tShipment rsh ON (roi.ShipmentId = rsh.Id)  
    WHERE (romItem.RemoteRowId = qit.Id)  
     AND (romItem.BusinessObjectTypeId = @botOIId)  
     AND (romItem.RemoteSystemId = @rsLocalId)  
   ), '')        AS [Related Invoice]  
  FROM tEXP_InvoiceDetails xid  
   JOIN tDAT_QuoteInvoicesDetails qid ON xid.InvoiceDetailId = qid.Id  
   JOIN tDAT_QuoteItem qit ON qid.QuoteItemUID = qit.FSP_UID  
   JOIN tDAT_QuoteInvoicesLinking qil ON qid.QuoteUID = qil.QuoteUID  
   JOIN tDAT_QuoteInvoices qi ON qi.InvoiceUID = qil.InvoiceUID  
   JOIN tDAT_NavCBData ncbd ON ncbd.UID = qil.QuoteUID  
   JOIN tDAT_Quote q ON q.FSP_UID = qil.QuoteUID  
   JOIN tRemoteObjectMapper rom ON rom.RemoteRowId = qit.ID AND rom.BusinessObjectTypeId = @botOIId  
   JOIN tOrderItem oi ON oi.Id = rom.LocalRowId AND rom.RemoteSystemId = @rsLocalId  
   JOIN tOrderItem oid on oid.TransactionGuid = oi.TransactionGuid
   JOIN tOrderProcessingState opsd on opsd.id = oid.orderprocessingstateid and opsd.Processtypeid = 1
    
    WHERE (xid.FileId = @Id)
  and ncbd.ProcessType = 2
  AND (xid.Exportable <> 0)
  and q.ShipToCode like 'ADV%'
  ORDER BY [Ref Number], [P/O Line]
END
GO



