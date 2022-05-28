DROP SCHEMA IF EXISTS "new" CASCADE;

CREATE SCHEMA IF NOT EXISTS "new" AUTHORIZATION postgres;

-- Drop table

DROP TABLE IF EXISTS "new".shipping_agreement CASCADE;

CREATE TABLE IF NOT EXISTS "new".shipping_agreement (
	agreementid int4 NOT NULL,
	agreement_number varchar(20) NULL,
	agreement_rate numeric(14, 2) NULL,
	agreement_commission numeric(14, 2) NULL,
	CONSTRAINT shipping_agreement_pk PRIMARY KEY (agreementid)
);


-- "new".shipping_country_rates definition

-- Drop table

DROP TABLE IF EXISTS "new".shipping_country_rates CASCADE;

CREATE TABLE IF NOT EXISTS "new".shipping_country_rates (
	shipping_country_id serial4 NOT NULL,
	shipping_country varchar(20) NULL,
	shipping_country_base_rate numeric(14, 2) NULL,
	CONSTRAINT shipping_country_rates_pk PRIMARY KEY (shipping_country_id)
);


-- "new".shipping_status definition

-- Drop table

DROP TABLE IF EXISTS "new".shipping_status CASCADE;

CREATE TABLE IF NOT EXISTS "new".shipping_status (
	shippingid int8 NULL,
	status varchar(20) NULL,
	state varchar(20) NULL,
	shipping_start_fact_datetime timestamp NULL,
	shipping_end_fact_datetime timestamp NULL
);


-- "new".shipping_transfer definition

-- Drop table

DROP TABLE IF EXISTS "new".shipping_transfer CASCADE;

CREATE TABLE IF NOT EXISTS "new".shipping_transfer (
	transfer_type_id serial4 NOT NULL,
	transfer_type varchar(20) NULL,
	transfer_model varchar(20) NULL,
	shipping_transfer_rate numeric(14, 3) NULL,
	CONSTRAINT shipping_transfer_pk PRIMARY KEY (transfer_type_id)
);


-- "new".shipping_info definition

-- Drop table

DROP TABLE IF EXISTS "new".shipping_info CASCADE;

CREATE TABLE IF NOT EXISTS "new".shipping_info (
	shippingid int8 NOT NULL,
	vendorid int8 NULL,
	payment_amount numeric(14, 2) NULL,
	shipping_plan_datetime timestamp NULL,
	transfer_type_id int8 NULL,
	shipping_country_id int8 NULL,
	agreementid int8 NULL,
	CONSTRAINT shipping_info_pk PRIMARY KEY (shippingid),
	CONSTRAINT shipping_info_countyrates FOREIGN KEY (shipping_country_id) REFERENCES "new".shipping_country_rates(shipping_country_id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT shipping_info_fk_agreement FOREIGN KEY (agreementid) REFERENCES "new".shipping_agreement(agreementid) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT shipping_info_fk_transfer FOREIGN KEY (transfer_type_id) REFERENCES "new".shipping_transfer(transfer_type_id) ON DELETE CASCADE ON UPDATE CASCADE
);


-- "new".shipping_datamart source

CREATE OR REPLACE VIEW "new".shipping_datamart
AS SELECT si.shippingid,
    si.vendorid,
    st.transfer_type,
    ss.shipping_end_fact_datetime > si.shipping_plan_datetime AS is_delay,
        CASE
            WHEN ss.status::text = 'finished'::text THEN true
            ELSE false
        END AS is_shipping_finish,
        CASE
            WHEN ss.shipping_end_fact_datetime > si.shipping_plan_datetime THEN EXTRACT(day FROM ss.shipping_end_fact_datetime - si.shipping_plan_datetime)
            ELSE 0::numeric
        END AS delay_day_at_shipping,
    si.payment_amount,
    si.payment_amount * (scr.shipping_country_base_rate + st.shipping_transfer_rate + sa.agreement_rate) AS vat,
    si.payment_amount * sa.agreement_commission AS profit
   FROM new.shipping_info si
     LEFT JOIN new.shipping_status ss ON ss.shippingid = si.shippingid
     LEFT JOIN new.shipping_country_rates scr ON si.shipping_country_id = scr.shipping_country_id
     LEFT JOIN new.shipping_transfer st ON si.transfer_type_id = st.transfer_type_id
     LEFT JOIN new.shipping_agreement sa ON si.agreementid = sa.agreementid;


-- "new".shipping source

CREATE OR REPLACE VIEW "new".shipping
AS SELECT shipping.id,
    shipping.shippingid,
    shipping.saleid,
    shipping.orderid,
    shipping.clientid,
    shipping.payment_amount,
    shipping.state_datetime,
    shipping.productid,
    shipping.description,
    shipping.vendorid,
    shipping.namecategory,
    shipping.base_country,
    shipping.status,
    shipping.state,
    shipping.shipping_plan_datetime,
    shipping.hours_to_plan_shipping,
    shipping.shipping_transfer_description,
    shipping.shipping_transfer_rate,
    shipping.shipping_country,
    shipping.shipping_country_base_rate,
    shipping.vendor_agreement_description
   FROM shipping;
