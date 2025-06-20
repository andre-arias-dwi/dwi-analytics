/*
Copy table with existing field, add fields with null if needed
CAST(NULL AS STRING) AS SourceSystem,
CAST(NULL AS DATE) AS DeliveryDate
*/
CREATE OR REPLACE TABLE `tough-healer-395417.analytics_staging.stg_order_details_historical`
PARTITION BY OrderDate
CLUSTER BY DWBRAND, ORDERTYPE, Customer_Status
OPTIONS(
  description = "REC008 order details historical table"
)
AS
SELECT
  ATGSalesOrderNumber,
  AXSalesOrderNumber,
  OrderDate,
  Customer_Status,
  ORDERTYPE,
  DWBRAND,
  Business_Partner,
  DWORDERTYPE,
  DWResponseCode,
  MarketingActivity,
  ReportingSalesActivity,
  Bottle_Quantity,
  Revenue,
  COUPON_CODE,
  SALESSTATUS,
  SalesOrderDate,
  media,
  BillingState,
  Shippingaddress
FROM `tough-healer-395417.analytics_unified.dim_order_details`
WHERE OrderDate < '2024-06-01'
