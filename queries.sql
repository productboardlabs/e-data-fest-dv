INSERT INTO beer_database
(name, id, brewery_id, cat_id, style_id, alcohol_by_volume, description, style, category, brewer)
VALUES ('pilsner urquell', 99999, 88888, '99', '99', 4.8, 'Very good anch tasty beer.', 'european lager', 'czech lager', 'pilsner urquell brewery in pilsen');

select *
from sat_beer
where name = 'pilsner urquell';

-- hash_key: d3eb9a9233e52948740d7eb8c3062d14

UPDATE beer_database
SET name = 'starobrno'
WHERE id = 99999;

select *
from sat_beer
where hash_key = 'd3eb9a9233e52948740d7eb8c3062d14'

-- >> two records, one closed (valid_to is not null), one active (valid to is null)


select
    hb.id as brewery_id, sb.brewer, sb.city,
    hbe.id as beer_id, sbe.name, sbe.style
from hub_brewery hb
inner join sat_brewery sb on sb.hash_key = hb.hash_key AND sb.valid_to is null
inner join link_brewery_beer l on l.brewery_hash_key = sb.hash_key
inner join satl_brewery_beer sl on sl.hash_key = l.hash_key AND sl.valid_to is null
inner join hub_beer hbe on hbe.hash_key = l.beer_hash_key
inner join sat_beer sbe on sbe.hash_key = hbe.hash_key AND sbe.valid_to is null
limit 10;