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
