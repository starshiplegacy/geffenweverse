-- Catálogo de Temas de Geffen Shop (USD 4.00 c/u). NO APLICADO: revisar y aplicar tras reconciliar el historial de migraciones.
-- Idempotente: no duplica productos si ya existen.
insert into public.products (cat, nombre, precio)
select 'temas', 'Tema ' || n, 4.00
from unnest(array['GeffenBlue','GeffenStar','Sumshine','Blue Moon','Dark Moon','Stellar','Cosmic Love','GeffenGord','Glue Gorld','Galaxy','Spring','Snow','Winter','Summer','Rainbow Geffen']) as n
where not exists (select 1 from public.products p where p.cat = 'temas' and p.nombre = 'Tema ' || n);
