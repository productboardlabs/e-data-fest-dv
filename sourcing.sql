CREATE OR REPLACE TABLE BEER_DATABASE AS
SELECT
    LOWER("Name") AS name,
    "id" AS id,
    "brewery_id" AS brewery_id,
    "cat_id" AS cat_id,
    "style_id" AS style_id,
    TRY_TO_DECIMAL("Alcohol_By_Volume",4,2) AS alcohol_by_volume,
    TRY_TO_NUMBER("International_Bitterness_Units") AS international_bitterness_units,
    TRY_TO_NUMBER("Standard_Reference_Method") AS standard_reference_method,
    LOWER("Description") AS description,
    LOWER("Style") AS style,
    LOWER("Category") AS category,
    LOWER("Brewer") AS brewer,
    LOWER("Address") AS address,
    LOWER("City") AS city,
    LOWER("State") AS state,
    LOWER("Country") AS country,
    "Coordinates" AS coordinates,
    "Website" AS website
FROM "in.beer_database"
WHERE TRY_TO_NUMBER("id") IS NOT NULL
AND TRY_TO_NUMBER("brewery_id") IS NOT NULL
ORDER BY 2
;

-- drop duplicates

create or replace sequence seq_1 start = 1 increment = 1;

alter table BEER_DATABASE
add column pk integer;

update BEER_DATABASE
set pk = seq_1.nextval;

delete from BEER_DATABASE
where pk in (
  select pk
  from (
      select pk
          ,ROW_NUMBER() OVER (partition by id, brewery_id order by pk)  AS rn
      from BEER_DATABASE
  )
  where rn > 1
);

alter table BEER_DATABASE
drop column pk;
