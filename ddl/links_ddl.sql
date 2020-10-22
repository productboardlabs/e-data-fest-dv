CREATE OR REPLACE TABLE link_brewery_beer (
    hash_key VARCHAR(255),
    valid_from TIMESTAMP_NTZ,
    source VARCHAR(255),
    brewery_hash_key VARCHAR(255),
    beer_hash_key VARCHAR(255)
);
