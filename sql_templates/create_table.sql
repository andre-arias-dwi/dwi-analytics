BEGIN

-- Drop the existing table if it exists
DROP TABLE IF EXISTS `tough-healer-395417.analytics_staging.stg_order_details`;

-- Recreate the table with the updated schema
CREATE TABLE `tough-healer-395417.analytics_staging.stg_order_details`
(
  ATGSalesOrderNumber      STRING,
  AXSalesOrderNumber       STRING,
  OrderDate                DATE,
  Customer_Status          STRING,
  ORDERTYPE                STRING,
  DWBRAND                  STRING,
  Business_Partner         STRING,
  DWORDERTYPE              STRING,
  DWResponseCode           STRING,
  MarketingActivity        STRING,
  ReportingSalesActivity   STRING,
  Bottle_Quantity          INT64,
  Revenue                  FLOAT64,
  COUPON_CODE              STRING,
  SALESSTATUS              STRING,
  SalesOrderDate           TIMESTAMP,
  media                    STRING,
  BillingState             STRING,
  Shippingaddress          STRING
)
PARTITION BY DATE(OrderDate)
CLUSTER BY DWBRAND, ORDERTYPE, Customer_Status
OPTIONS(
  description = "REC008 order details staged via SFTP to GCS, loaded to BigQuery with Data Transfer (MIRROR)"
);

END;
