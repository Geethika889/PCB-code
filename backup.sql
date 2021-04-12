  
CREATE PROCEDURE cbInvUploadSelectDataForADV  
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
  qid.VIN         AS [Ref Number],  
  ncbd.DocumentDate      AS [Ref Date],  
  qi.KreditorCode       AS [Dealer],  
  qi.InvoiceNo       AS [Dealer Invoice],  
  q.serviceDate       AS [Delivery Date],  
  q.ShipToCode       AS [Workshop],  
  qil.AuthorisationCode     AS [P/O Number],  
  qit.MP_ItemSequence      AS [P/O Line],  
  CAST(qid.Code AS varchar(20))   AS [Part Number],  
  CAST(qid.Description AS varchar(80)) AS [Description],  
  CASE WHEN qi.InvoiceType = 'D'  
   THEN qit.quantity  
   ELSE -qit.quantity  
  END          AS [Quantity],  
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
    oi.WholesalePrice * 1.1 * oi.Quantity   
   ELSE  
    -oi.WholesalePrice * 1.1 * oi.Quantity  
   END  
            AS [WDN+10% Net Value],  
  CASE WHEN oi.InvoicingTypeId = 0  
   THEN  
    oi.WholesalePrice * 1.1 * oi.TaxRate *.01 * oi.Quantity  
   ELSE  
    -oi.WholesalePrice * 1.1 * oi.TaxRate *.01 * oi.Quantity  
   END  
            AS [WDN+10% Vat Value],  
  CASE WHEN oi.InvoicingTypeId = 0  
   THEN  
    oi.WholesalePrice * oi.Quantity * 1.1 * (1 + oi.TaxRate * .01)  
   ELSE  
    -oi.WholesalePrice * oi.Quantity * 1.1 * (1 + oi.TaxRate * .01)  
   END  
            AS [WDN+10% Gross Value],  
  CASE WHEN oi.InvoicingTypeId = 0  
   THEN  
    oi.RetailPrice * oi.Quantity * .7  
   ELSE  
    -oi.RetailPrice * oi.Quantity * .7  
   END  
            AS [RRP-30% Net Value],  
  CASE WHEN oi.InvoicingTypeId = 0  
   THEN  
    oi.RetailPrice * oi.Quantity * .7 * oi.TaxRate * .01  
   ELSE  
    -oi.RetailPrice * oi.Quantity * .7 * oi.TaxRate * .01  
   END  
            AS [RRP-30% Vat Value],  
  CASE WHEN oi.InvoicingTypeId = 0  
   THEN  
    oi.RetailPrice * oi.Quantity * .7 * (1 + oi.TaxRate * .01)  
   ELSE  
    -oi.RetailPrice * oi.Quantity * .7 * (1 + oi.TaxRate * .01)  
   END  
            AS [RRP-30% Gross Value],  
  oi.condition AS [Applied Condition],  
  oi.TotalPrice AS [Agreed Net Value],  
  oi.TotalPrice * (oi.TaxRate * .01) AS [Agreed VAT Value],  
  oi.TotalPrice * (1 + oi.TaxRate * .01) AS [Agreed Gross Value],  
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
  WHERE (xid.FileId = @Id)  
   AND (xid.Exportable <> 0)  
  ORDER BY [Ref Number], [P/O Line]  
END  