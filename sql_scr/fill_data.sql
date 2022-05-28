-- shipping_agreement
DELETE  FROM new.shipping_country_rates;

INSERT INTO NEW.shipping_country_rates(shipping_country,shipping_country_base_rate)
SELECT DISTINCT 
s.shipping_country :: varchar(20),
s.shipping_country_base_rate :: NUMERIC(14,2)
FROM shipping s;

-- shipping_agreement
DELETE FROM new.shipping_agreement;

INSERT INTO new.shipping_agreement(agreementid,agreement_number,agreement_rate,agreement_commission)
SELECT DISTINCT 
(regexp_split_to_array(vendor_agreement_description,':'))[1] :: int AS agreementid,
(regexp_split_to_array(vendor_agreement_description,':'))[2] :: varchar(20) AS agreement_number,
(regexp_split_to_array(vendor_agreement_description,':'))[3] :: NUMERIC(14,2) AS agreement_rate,
(regexp_split_to_array(vendor_agreement_description,':'))[4] :: NUMERIC(14,2) AS agreement_commission
FROM shipping s;

-- shipping_transfer
DELETE FROM new.shipping_transfer;

INSERT INTO new.shipping_transfer(transfer_type,transfer_model,shipping_transfer_rate)
SELECT DISTINCT 
(regexp_split_to_array(shipping_transfer_description,':'))[1] :: varchar(20) AS transfer_type,
(regexp_split_to_array(shipping_transfer_description,':'))[2] :: varchar(20) AS transfer_model,
s.shipping_transfer_rate :: NUMERIC(14,3)
FROM shipping s;

-- shipping_info
DELETE FROM new.shipping_info;

INSERT INTO new.shipping_info(shippingid,shipping_plan_datetime,payment_amount,vendorid,shipping_country_id,agreementid,transfer_type_id)
SELECT DISTINCT
s.shippingid,
s.shipping_plan_datetime,
s.payment_amount,
s.vendorid,
(SELECT scr.shipping_country_id FROM "new".shipping_country_rates scr WHERE s.shipping_country = scr.shipping_country),
(SELECT sa.agreementid FROM "new".shipping_agreement sa WHERE (regexp_split_to_array(s.vendor_agreement_description,':'))[1] :: int = sa.agreementid),
(SELECT st.transfer_type_id FROM "new".shipping_transfer st WHERE concat(st.transfer_type,':',st.transfer_model) = s.shipping_transfer_description)
FROM shipping s;

-- shipping_status
DELETE FROM new.shipping_status;

INSERT INTO new.shipping_status
(shippingid,status,state,shipping_start_fact_datetime,shipping_end_fact_datetime)
WITH cte AS(
SELECT DISTINCT 
s.shippingid,
max(state_datetime) AS shipping_end_fact_datetime
FROM shipping s
WHERE s.state = 'recieved'
GROUP BY 1),
cte2 as(
SELECT DISTINCT 
s.shippingid,
max(state_datetime) AS shipping_start_fact_datetime
FROM shipping s
WHERE s.state = 'booked'
GROUP BY 1),
cte3 AS (SELECT DISTINCT shippingid,
max(state_datetime)
FROM shipping
GROUP BY 1)
SELECT 
cte3.shippingid :: BIGINT,
s2.status :: varchar(20),
s2.state :: varchar(20),
cte2.shipping_start_fact_datetime :: TIMESTAMP,
cte.shipping_end_fact_datetime :: TIMESTAMP
FROM cte3
LEFT JOIN shipping s2 ON s2.shippingid = cte3.shippingid AND s2.state_datetime = cte3.max
LEFT JOIN cte ON cte.shippingid = cte3.shippingid
LEFT JOIN cte2 ON cte2.shippingid = cte3.shippingid