# Základy DV - modelování pivovarů a piv


## Průběh praktické části:

* Vývojové prostředí - Snowflake
* Představení domény
* DV model
* Stavba DWH
    * huby
    * satelity
    * linky
* Dotazy nad DV

* Repo link: https://github.com/productboardlabs/e-data-fest-dv

---

## Vývojové prostředí - Snowflake
* Web UI
* Přihlašovací údaje v emailu
* Kdo nedostal, napište do chatu - pokusíme se to ještě zařídit

---

## Představení domény
* https://www.kaggle.com/nickhould/craft-cans?select=breweries.csv
* 2 entity
    * brewery
    * beer
* Do další normalizace zacházet nebudeme

---

## DV Model
* https://github.com/productboardlabs/e-data-fest-dv/blob/main/model.png
* 2 entity => 2 huby
    * `hub_beer`
    * `hub_brewery`
* ke každému hubu jeden satelit
    * `sat_beer`
    * `sat_brewery`
* propojení přes link
    * `link_brewery_beer`
    * včetně historizace přes satelit nad linkem
        * `satl_brewery_beer`
        
---

## Stavíme DWH: Vytvoření tabulek


### `hub_beer`
* Hub nám identifikuje nějakou entitu
* Obsahuje pouze:
    * `hash_key` - PK v rámci DWH
    * `valid_from` - timestamp přidání záznamu do tabulky
    * `source` - identifikace datového zdroje
    * `id` - PK v datovém zdroji
        * nemusí to být nutně pouze `id`, ale 

```sql
CREATE OR REPLACE TABLE hub_beer (
    hash_key VARCHAR(255),
    valid_from TIMESTAMP_NTZ,
    source VARCHAR(255),
    id INTEGER
);
```


### `hub_brewery`
* Vyzkoušejte si sami
* SQL najdete v `ddl/hubs_ddl.sql`


### `link_brewery_beer`
* Link nám drží relaci mezi pivem a pivovarem
* Obsahuje pouze:
    * `hash_key` - PK v rámci DWH
    * `valid_from` - timestamp přidání záznamu do tabulky
    * `source` - identifikace datového zdroje
    * `brewery_hash_key` - PK brewery v DV
    * `beer_hash_key` - PK beer v DV
    
 ```sql
CREATE OR REPLACE TABLE link_brewery_beer (
    hash_key VARCHAR(255),
    valid_from TIMESTAMP_NTZ,
    source VARCHAR(255),
    brewery_hash_key VARCHAR(255),
    beer_hash_key VARCHAR(255)
);
```


### `sat_beer`
* V satelitu máme uložené veškeré informace k dané entitě
* V základu obsahuje vždy:
    * `hash_key` - PK v rámci DWH
    * `source` - identifikace datového zdroje, většinou identický se zdrojem v hubu
    * `valid_from` - timestamp přidání záznamu do tabulky
    * `valid_to` - timestamp uzavření platnosti záznamu
        * jedná se o **technické** timestampy, nikoliv businessové
    
* Dále pak ostatní sloupce:
    * `name`, `alcohol_by_volume`, ...

```sql
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
```


### `sat_brewery`
* Vyzkoušejte si sami
* SQL najdete v `ddl/sats_ddl.sql`



### `satl_brewery_beer`
* Samostatný link nám neumožňuje verzování - je zde pouze `valid_from`, nikoliv už `valid_to`
* Pro historizaci a případně další informace k linku souží zase satelit

* V základu obsahuje vždy:
    * `hash_key` - PK v rámci DWH, identický se záznamem v linku
    * `source` - identifikace datového zdroje, většinou identický se zdrojem v linku
    * `valid_from` - timestamp přidání záznamu do tabulky
    * `valid_to` - timestamp uzavření platnosti záznamu
        * jedná se zase o **technické** timestampy, nikoliv businessové
    
 ```sql
CREATE OR REPLACE TABLE link_brewery_beer (
    hash_key VARCHAR(255),
    valid_from TIMESTAMP_NTZ,
    source VARCHAR(255),
    brewery_hash_key VARCHAR(255),
    beer_hash_key VARCHAR(255)
);
```

---

## Stavíme DWH: Plnění tabulek

### `hub_beer`

```sql
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
```

### `hub_brewery`
* Zkuste sami


### `link_brewery_beer`

```sql
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
```

### `sat_beer`
* Insert do satelitu je v základu jedoduchá věc, ale skládá se ze tří částí:
    * Insert nových nebo změněných záznamů
    * Uzavření aktualizovaných záznamů přes technické timestampy
    * Uzavření již neexistujících záznamů


* Insert nových nebo zmeněných záznamů

```sql
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
```

* Uzavření aktualizovaných záznamů

```sql
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
```

* Uzavření již neexistujících záznamů

```sql
UPDATE sat_beer sat
	SET valid_to = $LOAD_DATE
WHERE sat.valid_to IS NULL AND NOT EXISTS (SELECT 1 FROM beer_database i WHERE DV_HASH(i.id) = sat.hash_key);
```

### `sat_brewery`
* Zkuste sami

### `satl_brewery_beer`
* Tento satelit neobsahuje žádné informace navíc, takže nám vypadne query na uzavírání aktualizovaných záznamů
* Jinak se ale ničím neliší od klasického satelitu k hubu

```sql
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
```


---

## Dotazování nad DV


### Získání nejaktuálnějších dat
* Filtrujeme vždy přes `sat.valid_to IS NULL`


### Získání historických dat
* Využijeme `sat.valid_from`

### Ukázka historizace

### Zkuste sami:
* Napište dotaz, který vám zobrazí nejaktuálnější data a tyto fieldy
    * `brewery_id, brewer, city, beer_id, beer_name, beer_style`
* Tip: Začněte třeba od `hub_brewery` a projoinujte se až k datům o pivech
* Nezapomeňte správně použít `valid_to` filtr na satelitech!


