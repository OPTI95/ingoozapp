-- Добавляет в таблицу cars поля собственника ТС (жёлтый блок в путевом листе).
-- Выполнить один раз в Supabase SQL Editor.

alter table public.cars
  add column if not exists owner_name text,
  add column if not exists owner_inn text,
  add column if not exists owner_address text,
  add column if not exists owner_phone text;

comment on column public.cars.owner_name is 'ФИО/наименование собственника ТС';
comment on column public.cars.owner_inn is 'ИНН собственника ТС';
comment on column public.cars.owner_address is 'Адрес собственника ТС';
comment on column public.cars.owner_phone is 'Телефон собственника ТС';

