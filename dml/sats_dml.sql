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
