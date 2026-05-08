SELECT  
month,
customer_status,
state_group,
order_type,
count(DISTINCT transaction_id) as transactions,
FROM `tough-healer-395417.GA4_reporting.WSJ_state_level`
where period = 'Current Year'
GROUP BY
    all
