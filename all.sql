CREATE OR REPLACE FUNCTION DV_HASH(
    value1 VARCHAR
    )
RETURNS VARCHAR
IMMUTABLE
AS
    $$
       MD5(
           COALESCE(CAST(value1 as VARCHAR(1000)), '')
       )
    $$;

CREATE OR REPLACE FUNCTION DV_HASH(
    value1 VARCHAR,
    value2 VARCHAR
    )
RETURNS VARCHAR
IMMUTABLE
AS
    $$
       MD5(
           COALESCE(CAST(value1 as VARCHAR(1000)), '') || ';' ||
           COALESCE(CAST(value2 as VARCHAR(1000)),'')
       )
    $$;

SET LOAD_DATE = TO_CHAR(CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP()), 'YYYY-MM-DD HH24:MI:SS');


CREATE OR REPLACE TABLE hub_beer (
    hash_key VARCHAR(255),
    valid_from TIMESTAMP_NTZ,
    source VARCHAR(255),
    id INTEGER
);

CREATE OR REPLACE TABLE hub_brewery (
    hash_key VARCHAR(255),
    valid_from TIMESTAMP_NTZ,
    source VARCHAR(255),
    id INTEGER
);

CREATE OR REPLACE TABLE link_brewery_beer (
    hash_key VARCHAR(255),
    valid_from TIMESTAMP_NTZ,
    source VARCHAR(255),
    brewery_hash_key VARCHAR(255),
    beer_hash_key VARCHAR(255)
);

CREATE OR REPLACE TABLE sat_beer (
    hash_key VARCHAR(255),
    valid_from TIMESTAMP_NTZ,
    valid_to TIMESTAMP_NTZ,
    source VARCHAR(255),
    name VARCHAR(255),
    alcohol_by_volume DECIMAL(4,2),
    international_bitterness_units INTEGER,
    description VARCHAR(10000),
    style VARCHAR(255),
    category VARCHAR(255)
);


CREATE OR REPLACE TABLE sat_brewery (
    hash_key VARCHAR(255),
    valid_from TIMESTAMP_NTZ,
    valid_to TIMESTAMP_NTZ,
    source VARCHAR(255),
    brewer VARCHAR(255),
    address VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    country VARCHAR(255),
    coordinates VARCHAR(255),
    website VARCHAR(255)
);


CREATE OR REPLACE TABLE satl_brewery_beer (
    hash_key VARCHAR(255),
    valid_from TIMESTAMP_NTZ,
    valid_to TIMESTAMP_NTZ,
    source VARCHAR(255)
);

-- hub_beer

INSERT INTO hub_beer
(
  hash_key,
  valid_from,
  source,
  id
)
SELECT DISTINCT
        DV_HASH(i.id) AS hash_key,
        $LOAD_DATE AS valid_from,
        'beer_database' AS source,
        i.id AS id
FROM beer_database i
WHERE DV_HASH(i.id) NOT IN (SELECT s.hash_key FROM hub_beer s)
;

-- hub_brewery

INSERT INTO hub_brewery
(
  hash_key,
  valid_from,
  source,
  id
)
SELECT DISTINCT
        DV_HASH(i.brewery_id) AS hash_key,
        $LOAD_DATE AS valid_from,
        'beer_database' AS source,
        i.brewery_id AS id
FROM beer_database i
WHERE DV_HASH(i.id) NOT IN (SELECT s.hash_key FROM hub_brewery s)
;


-- link_brewery_beer

INSERT INTO link_brewery_beer
(
  hash_key,
  valid_from,
  source,
  brewery_hash_key,
  beer_hash_key
)
SELECT DISTINCT
       DV_HASH(i.brewery_id,i.id) as hash_key,
       $LOAD_DATE as valid_from,
       'beer_database' as source,
       DV_HASH(i.brewery_id) as brewery_hash_key,
       DV_HASH(i.id) as beer_hash_key
FROM beer_database i
WHERE DV_HASH(i.brewery_id,i.id) NOT IN (SELECT u.hash_key FROM link_brewery_beer u);

-- sat_beer
-- Insert all new records
INSERT INTO sat_beer
(
  hash_key,
  valid_from,
  valid_to,
  source,
  name,
  alcohol_by_volume,
  international_bitterness_units,
  description,
  style,
  category
)
SELECT DISTINCT
    DV_HASH(i.id) AS hash_key,
    $LOAD_DATE AS valid_from,
    NULL AS valid_to,
    'beer_database' AS source,
    i.name AS name,
    i.alcohol_by_volume AS alcohol_by_volume,
    i.international_bitterness_units AS international_bitterness_units,
    i.description AS description,
    i.style AS style,
    i.category AS category
FROM beer_database i
LEFT  JOIN sat_beer sat ON DV_HASH(i.id) = sat.hash_key AND sat.valid_to IS NULL
WHERE
    NOT EQUAL_NULL(i.name,sat.name)
    	OR
    NOT EQUAL_NULL(i.alcohol_by_volume,sat.alcohol_by_volume)
    	OR
    NOT EQUAL_NULL(i.international_bitterness_units,sat.international_bitterness_units)
    	OR
    NOT EQUAL_NULL(i.description,sat.description)
    	OR
    NOT EQUAL_NULL(i.style,sat.style)
    	OR
    NOT EQUAL_NULL(i.category,sat.category)
;

-- Update valid_to for all old versions of updated entities
UPDATE sat_beer sat
    SET valid_to = $LOAD_DATE
WHERE sat.valid_to IS NULL AND EXISTS (
      SELECT 1 FROM sat_beer i
      WHERE
        i.hash_key = sat.hash_key
            AND
        i.valid_to IS NULL
            AND
        i.valid_from > sat.valid_from
    );

-- Update valid_to for deleted records
UPDATE sat_beer sat
	SET valid_to = $LOAD_DATE
WHERE sat.valid_to IS NULL AND NOT EXISTS (SELECT 1 FROM beer_database i WHERE DV_HASH(i.id) = sat.hash_key);


--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------


-- sat_brewery
-- Insert all new records
INSERT INTO sat_brewery
(
  hash_key,
  valid_from,
  valid_to,
  source,
  brewer,
  address,
  city,
  state,
  country,
  coordinates,
  website
)
SELECT DISTINCT
    DV_HASH(i.brewery_id) AS hash_key,
    $LOAD_DATE AS valid_from,
    NULL AS valid_to,
    'beer_database' AS source,
    i.brewer AS brewer,
    i.address AS address,
    i.city AS city,
    i.state AS state,
    i.country AS country,
    i.coordinates AS coordinates,
    i.website AS website
FROM beer_database i
LEFT  JOIN sat_brewery sat ON DV_HASH(i.id) = sat.hash_key AND sat.valid_to IS NULL
WHERE
    NOT EQUAL_NULL(i.brewer,sat.brewer)
    	OR
    NOT EQUAL_NULL(i.address,sat.address)
    	OR
    NOT EQUAL_NULL(i.city,sat.city)
    	OR
    NOT EQUAL_NULL(i.state,sat.state)
    	OR
    NOT EQUAL_NULL(i.country,sat.country)
    	OR
    NOT EQUAL_NULL(i.coordinates,sat.coordinates)
        OR
    NOT EQUAL_NULL(i.website,sat.website)
;

-- Update valid_to for all old versions of updated entities
UPDATE sat_brewery sat
    SET valid_to = $LOAD_DATE
WHERE sat.valid_to IS NULL AND EXISTS (
      SELECT 1 FROM sat_brewery i
      WHERE
        i.hash_key = sat.hash_key
            AND
        i.valid_to IS NULL
            AND
        i.valid_from > sat.valid_from
    );

-- Update valid_to for deleted records
UPDATE sat_brewery sat
	SET valid_to = $LOAD_DATE
WHERE sat.valid_to IS NULL AND NOT EXISTS (SELECT 1 FROM beer_database i WHERE DV_HASH(i.brewery_id) = sat.hash_key);



--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------



-- satl_brewery_beer
-- Insert all new records
INSERT INTO satl_brewery_beer
(
  hash_key,
  valid_from,
  valid_to,
  source
)
SELECT DISTINCT
       DV_HASH(i.brewery_id,i.id) as hash_key,
       $LOAD_DATE as valid_from,
       NULL as valid_to,
       'beer_database' as source
FROM beer_database i
WHERE DV_HASH(i.brewery_id,i.id) NOT IN (SELECT u.hash_key FROM satl_brewery_beer u WHERE u.valid_to IS NULL)
;

-- Update valid_to for deleted records
UPDATE satl_brewery_beer sat
	SET valid_to = $LOAD_DATE
WHERE sat.valid_to IS NULL AND NOT EXISTS (SELECT 1 FROM beer_database i WHERE DV_HASH(i.brewery_id,i.id) = sat.hash_key)
;
