-- ============================================================
-- NEXAPROC — Schema limpio (versión con DROP)
-- Si ya tienes tablas creadas, esto las elimina y recrea.
-- ADVERTENCIA: Borra todos los datos existentes.
-- ============================================================

-- Borrar policies primero
drop policy if exists "profiles: ver propio" on public.profiles;
drop policy if exists "profiles: editar propio" on public.profiles;
drop policy if exists "suppliers: ver todos" on public.suppliers;
drop policy if exists "suppliers: editar propio" on public.suppliers;
drop policy if exists "products: ver activos" on public.products;
drop policy if exists "products: supplier CRUD" on public.products;
drop policy if exists "rfqs: buyer ve suyos" on public.rfqs;
drop policy if exists "rfqs: supplier ve abiertos" on public.rfqs;
drop policy if exists "rfqs: buyer crea" on public.rfqs;
drop policy if exists "rfqs: buyer edita suyos" on public.rfqs;
drop policy if exists "quotes: supplier ve suyos" on public.quotes;
drop policy if exists "quotes: buyer ve de sus rfqs" on public.quotes;
drop policy if exists "quotes: supplier crea" on public.quotes;
drop policy if exists "quotes: supplier edita suyos" on public.quotes;
drop policy if exists "po: buyer ve suyos" on public.purchase_orders;
drop policy if exists "po: supplier ve suyos" on public.purchase_orders;
drop policy if exists "po: buyer crea" on public.purchase_orders;
drop policy if exists "product images: ver público" on storage.objects;
drop policy if exists "product images: supplier sube" on storage.objects;

-- Borrar triggers
drop trigger if exists set_po_number on public.purchase_orders;
drop trigger if exists profiles_updated_at on public.profiles;
drop trigger if exists products_updated_at on public.products;
drop trigger if exists rfqs_updated_at on public.rfqs;
drop trigger if exists quotes_updated_at on public.quotes;

-- Borrar funciones
drop function if exists generate_po_number();
drop function if exists update_updated_at();

-- Borrar tablas (cascade elimina foreign keys automáticamente)
drop table if exists public.purchase_orders cascade;
drop table if exists public.quote_items cascade;
drop table if exists public.quotes cascade;
drop table if exists public.rfqs cascade;
drop table if exists public.products cascade;
drop table if exists public.suppliers cascade;
drop table if exists public.profiles cascade;

-- ============================================================
-- CREAR TODO DESDE CERO
-- ============================================================

create extension if not exists "uuid-ossp";

create table public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  role          text not null check (role in ('buyer', 'supplier')),
  full_name     text not null,
  company_name  text not null,
  ruc           text not null,
  phone         text,
  avatar_url    text,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

create table public.suppliers (
  id                   uuid primary key references public.profiles(id) on delete cascade,
  company_name         text not null,
  description          text,
  category             text[] default '{}',
  verified             boolean default false,
  rating               numeric(3,2) default 0,
  review_count         integer default 0,
  location             text,
  logo_url             text,
  website              text,
  certifications       text[] default '{}',
  response_time_hours  integer,
  created_at           timestamptz default now()
);

create table public.products (
  id              uuid primary key default uuid_generate_v4(),
  supplier_id     uuid not null references public.suppliers(id) on delete cascade,
  name            text not null,
  description     text,
  price           numeric(12,2),
  price_unit      text,
  stock_status    text default 'available' check (stock_status in ('available', 'low', 'out_of_stock', 'on_demand')),
  stock_qty       integer,
  images          text[] default '{}',
  category        text not null,
  sku             text,
  min_order_qty   integer default 1,
  lead_time_days  integer,
  is_active       boolean default true,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

create index products_supplier_active_idx on public.products(supplier_id, is_active);
create index products_search_idx on public.products using gin(to_tsvector('spanish', name || ' ' || coalesce(description, '')));

create table public.rfqs (
  id                 uuid primary key default uuid_generate_v4(),
  buyer_id           uuid not null references public.profiles(id) on delete cascade,
  title              text not null,
  description        text,
  category           text not null,
  quantity           text not null,
  deadline           date not null,
  delivery_location  text,
  budget_max         numeric(12,2),
  status             text default 'open' check (status in ('draft', 'open', 'closed', 'cancelled')),
  created_at         timestamptz default now(),
  updated_at         timestamptz default now()
);

create table public.quotes (
  id               uuid primary key default uuid_generate_v4(),
  rfq_id           uuid not null references public.rfqs(id) on delete cascade,
  supplier_id      uuid not null references public.suppliers(id) on delete cascade,
  unit_price       numeric(12,2) not null,
  total_price      numeric(12,2) not null,
  currency         text default 'PEN' check (currency in ('PEN', 'USD')),
  delivery_days    integer not null,
  delivery_terms   text,
  validity_days    integer default 30,
  notes            text,
  status           text default 'pending' check (status in ('pending', 'accepted', 'rejected', 'expired')),
  created_at       timestamptz default now(),
  updated_at       timestamptz default now(),
  unique(rfq_id, supplier_id)
);

create table public.quote_items (
  id           uuid primary key default uuid_generate_v4(),
  quote_id     uuid not null references public.quotes(id) on delete cascade,
  description  text not null,
  quantity     numeric(10,2) not null,
  unit         text not null,
  unit_price   numeric(12,2) not null,
  total_price  numeric(12,2) generated always as (quantity * unit_price) stored
);

create table public.purchase_orders (
  id               uuid primary key default uuid_generate_v4(),
  po_number        text unique not null default 'TEMP',
  quote_id         uuid not null references public.quotes(id),
  buyer_id         uuid not null references public.profiles(id),
  supplier_id      uuid not null references public.suppliers(id),
  total_amount     numeric(12,2) not null,
  currency         text default 'PEN',
  status           text default 'sent' check (status in ('draft', 'sent', 'confirmed', 'delivered', 'cancelled')),
  delivery_address text,
  notes            text,
  issued_at        timestamptz default now(),
  confirmed_at     timestamptz,
  delivered_at     timestamptz
);

create or replace function generate_po_number()
returns trigger as $$
declare
  year_str text;
  seq_num  integer;
begin
  year_str := to_char(now(), 'YYYY');
  select count(*) + 1 into seq_num
  from public.purchase_orders
  where po_number like 'PO-' || year_str || '-%';
  new.po_number := 'PO-' || year_str || '-' || lpad(seq_num::text, 4, '0');
  return new;
end;
$$ language plpgsql;

create trigger set_po_number
  before insert on public.purchase_orders
  for each row execute function generate_po_number();

create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at before update on public.profiles for each row execute function update_updated_at();
create trigger products_updated_at before update on public.products for each row execute function update_updated_at();
create trigger rfqs_updated_at before update on public.rfqs for each row execute function update_updated_at();
create trigger quotes_updated_at before update on public.quotes for each row execute function update_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.profiles enable row level security;
alter table public.suppliers enable row level security;
alter table public.products enable row level security;
alter table public.rfqs enable row level security;
alter table public.quotes enable row level security;
alter table public.quote_items enable row level security;
alter table public.purchase_orders enable row level security;

create policy "profiles: ver propio" on public.profiles for select using (auth.uid() = id);
create policy "profiles: editar propio" on public.profiles for update using (auth.uid() = id);

create policy "suppliers: ver todos" on public.suppliers for select to authenticated using (true);
create policy "suppliers: editar propio" on public.suppliers for update using (auth.uid() = id);

create policy "products: ver activos" on public.products for select to authenticated using (is_active = true);
create policy "products: supplier CRUD" on public.products for all using (auth.uid() = supplier_id);

create policy "rfqs: buyer ve suyos" on public.rfqs for select using (auth.uid() = buyer_id);
create policy "rfqs: supplier ve abiertos" on public.rfqs for select to authenticated using (status = 'open');
create policy "rfqs: buyer crea" on public.rfqs for insert with check (auth.uid() = buyer_id);
create policy "rfqs: buyer edita suyos" on public.rfqs for update using (auth.uid() = buyer_id);

create policy "quotes: supplier ve suyos" on public.quotes for select using (auth.uid() = supplier_id);
create policy "quotes: buyer ve de sus rfqs" on public.quotes for select using (
  auth.uid() in (select buyer_id from public.rfqs where id = rfq_id)
);
create policy "quotes: supplier crea" on public.quotes for insert with check (auth.uid() = supplier_id);
create policy "quotes: supplier edita suyos" on public.quotes for update using (auth.uid() = supplier_id);

create policy "po: buyer ve suyos" on public.purchase_orders for select using (auth.uid() = buyer_id);
create policy "po: supplier ve suyos" on public.purchase_orders for select using (auth.uid() = supplier_id);
create policy "po: buyer crea" on public.purchase_orders for insert with check (auth.uid() = buyer_id);

-- Storage
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

create policy "product images: ver público" on storage.objects
  for select using (bucket_id = 'product-images');
create policy "product images: supplier sube" on storage.objects
  for insert with check (bucket_id = 'product-images' and auth.role() = 'authenticated');
