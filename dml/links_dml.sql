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

