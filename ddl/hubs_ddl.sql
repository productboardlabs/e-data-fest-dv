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
