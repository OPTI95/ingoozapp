-- Добавляет в таблицу cars поля типа лицензиата.
-- Выполнить один раз в Supabase SQL Editor.

alter table public.cars
  add column if not exists license_type text,
  add column if not exists license_type_other_label text;

comment on column public.cars.license_type is
  'Тип лицензиата: individual|sole|ooo|ao|other';
comment on column public.cars.license_type_other_label is
  'Свободный тип лицензиата, если выбран other';

