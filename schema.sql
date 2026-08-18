-- =====================================================================
-- Pendientes Luijo — esquema de base de datos para Supabase
-- =====================================================================
-- Cómo usar:
-- 1. Entra a tu proyecto en https://app.supabase.com
-- 2. Ve a "SQL Editor" > "New query"
-- 3. Pega TODO este archivo y dale "Run"
-- 4. Repite para actualizaciones futuras (es seguro volver a correrlo,
--    usa "if not exists" / "on conflict" donde aplica)
-- =====================================================================

-- Extensión para generar UUIDs
create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------
-- Tabla: team_members (equipo)
-- ---------------------------------------------------------------------
create table if not exists team_members (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- Tabla: pendientes (tareas)
-- ---------------------------------------------------------------------
create table if not exists pendientes (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text default '',
  assignee_id uuid references team_members(id) on delete set null,
  status text not null default 'todo'
    check (status in ('todo', 'in_progress', 'done')),
  priority text not null default 'media'
    check (priority in ('alta', 'media', 'baja')),
  project text default '',
  due_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_pendientes_status on pendientes(status);
create index if not exists idx_pendientes_assignee on pendientes(assignee_id);

-- Mantener updated_at al día automáticamente
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_pendientes_updated_at on pendientes;
create trigger trg_pendientes_updated_at
  before update on pendientes
  for each row
  execute function set_updated_at();

-- ---------------------------------------------------------------------
-- Tabla: comentarios (historial / notas dentro de cada pendiente)
-- ---------------------------------------------------------------------
create table if not exists comentarios (
  id uuid primary key default gen_random_uuid(),
  pendiente_id uuid not null references pendientes(id) on delete cascade,
  author text not null default 'Alguien del equipo',
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_comentarios_pendiente on comentarios(pendiente_id);

-- ---------------------------------------------------------------------
-- Seguridad (RLS) — acceso compartido simple
-- ---------------------------------------------------------------------
-- Este proyecto usa "acceso compartido": no hay login individual, todo
-- el equipo usa la misma anon key. Por eso habilitamos RLS pero con
-- políticas abiertas para el rol anon (lectura y escritura). La única
-- barrera de entrada es la clave que se pide dentro de la app (no es
-- seguridad real: cualquiera con la anon key podría saltarla). Si más
-- adelante quieres seguridad de verdad, cambia a Supabase Auth y
-- restringe estas políticas por usuario.

alter table team_members enable row level security;
alter table pendientes enable row level security;
alter table comentarios enable row level security;

drop policy if exists "anon full access" on team_members;
create policy "anon full access" on team_members
  for all using (true) with check (true);

drop policy if exists "anon full access" on pendientes;
create policy "anon full access" on pendientes
  for all using (true) with check (true);

drop policy if exists "anon full access" on comentarios;
create policy "anon full access" on comentarios
  for all using (true) with check (true);

-- ---------------------------------------------------------------------
-- Seed: equipo inicial
-- ---------------------------------------------------------------------
insert into team_members (name) values
  ('Luis Jose Alvarez'),
  ('Soul Tovar'),
  ('Laura Zamora'),
  ('Hector Moreira'),
  ('Alejandro Martinez'),
  ('Vania Freyre')
on conflict (name) do nothing;

-- ---------------------------------------------------------------------
-- Habilitar Realtime (opcional pero recomendado): permite que el
-- tablero se actualice solo cuando alguien más mueve o edita un
-- pendiente, sin recargar la página.
-- ---------------------------------------------------------------------
do $$
begin
  alter publication supabase_realtime add table pendientes;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table comentarios;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table team_members;
exception when duplicate_object then null;
end $$;
