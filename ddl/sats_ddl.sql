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
