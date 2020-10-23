CREATE OR REPLACE TABLE "in.beer_database_source" AS 
SELECT 
    LOWER("Name") AS "NAME",
    "id" AS "ID",
    "brewery_id" AS "BREWERY_ID",
    "cat_id" AS "CAT_ID",
    "style_id" AS "STYLE_ID",
    TRY_TO_DECIMAL("Alcohol_By_Volume",4,2) AS "ALCOHOL_BY_VOLUME",
    TRY_TO_NUMBER("International_Bitterness_Units") AS "INTERNATIONAL_BITTERNESS_UNITS",
    TRY_TO_NUMBER("Standard_Reference_Method") AS "STANDARD_REFERENCE_METHOD",
    LOWER("Description") AS "DESCRIPTION",
    LOWER("Style") AS "STYLE",
    LOWER("Category") AS "CATEGORY",
    LOWER("Brewer") AS "BREWER",
    LOWER("Address") AS "ADDRESS",
    LOWER("City") AS "CITY",
    LOWER("State") AS "STATE",
    LOWER("Country") AS "COUNTRY",
    MAX("Coordinates") AS "COORDINATES",
    "Website" AS "WEBSITE"
FROM "in.beer_database" 
WHERE TRY_TO_NUMBER("id") IS NOT NULL 
AND TRY_TO_NUMBER("brewery_id") IS NOT NULL 
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,18
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
