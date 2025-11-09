-------------------------------------------------
-- 0. CONFIGURACIÓN INICIAL
-------------------------------------------------
create extension if not exists "pgcrypto"; -- para gen_random_uuid()

-------------------------------------------------
-- 1. SEGURIDAD Y ADMINISTRACIÓN BÁSICA
-------------------------------------------------

-- Resumen rápido de módulos:
-- | Módulo          | Entidades principales                           |
-- | bases           | clientes, direcciones, productos, hubs          |
-- | pedidos         | pedidos, detalle, viajes                        |
-- | operaciones     | movimientos, destinos, incidentes               |
-- | finanzas        | cuentas, pagos, cargos, gastos                  |
-- | almacen         | asignaciones y entregas en ruta                 |
-- | administracion  | perfiles y catálogos internos                   |

-------------------------------------------------
-- 1.1 Catálogos y tablas de seguridad
-------------------------------------------------

create table if not exists security_modules (
  nombre text primary key,
  descripcion text
);

insert into security_modules (nombre, descripcion) values
  ('bases', 'Catálogos maestros'),
  ('pedidos', 'Registro y edición de pedidos'),
  ('operaciones', 'Movimientos y destinos'),
  ('finanzas', 'Pagos y cargos'),
  ('almacen', 'Control de almacén y entregas'),
  ('administracion', 'Gestión interna y perfiles')
on conflict (nombre) do nothing;

create table if not exists security_roles (
  rol text primary key,
  descripcion text
);

insert into security_roles (rol, descripcion) values
  ('admin', 'Acceso total'),
  ('despacho', 'Usuarios de almacén'),
  ('atencion', 'Equipo de pedidos/operaciones')
on conflict (rol) do nothing;

create table if not exists role_modules (
  rol text references security_roles(rol) on delete cascade,
  modulo text references security_modules(nombre) on delete cascade,
  primary key (rol, modulo)
);

insert into role_modules (rol, modulo) values
  ('admin', 'bases'),
  ('admin', 'pedidos'),
  ('admin', 'operaciones'),
  ('admin', 'finanzas'),
  ('admin', 'almacen'),
  ('admin', 'administracion'),
  ('despacho', 'almacen'),
  ('atencion', 'pedidos'),
  ('atencion', 'operaciones')
on conflict (rol, modulo) do nothing;

create table if not exists security_resource_modules (
  schema_name text not null default 'public',
  relation_name text not null,
  modulo text not null references security_modules(nombre),
  ops text[] not null default array['select','insert','update','delete'],
  primary key (schema_name, relation_name)
);

insert into security_resource_modules (relation_name, modulo) values
  ('clientes', 'bases'),
  ('direccion', 'bases'),
  ('direccion_provincia', 'bases'),
  ('numrecibe', 'bases'),
  ('categorias', 'bases'),
  ('productos', 'bases'),
  ('bases', 'bases'),
  ('pedidos', 'pedidos'),
  ('detallepedidos', 'pedidos'),
  ('movimientopedidos', 'operaciones'),
  ('mov_destino_lima', 'operaciones'),
  ('mov_destino_provincia', 'operaciones'),
  ('detallemovimientopedidos', 'almacen'),
  ('viajes', 'pedidos'),
  ('viajesdetalles', 'almacen'),
  ('incidentes', 'operaciones'),
  ('cuentas_bancarias', 'finanzas'),
  ('pagos', 'finanzas'),
  ('gastos_operativos', 'finanzas'),
  ('cargos_cliente', 'finanzas')
on conflict (schema_name, relation_name) do nothing;

create table if not exists perfiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nombre text,
  rol text not null references security_roles(rol) default 'atencion',
  activo boolean not null default true,
  registrado_at timestamptz default now(),
  editado_at timestamptz default now(),
  registrado_por uuid,
  editado_por uuid
);

-------------------------------------------------
-- 1.2 Funciones auxiliares
-------------------------------------------------

create or replace function public.fn_perfiles_handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_is_first_admin boolean;
  v_rol text := 'atencion';
begin
  -- Garantiza que sólo un registro evalúe el rol inicial al mismo tiempo
  lock table public.perfiles in share row exclusive mode;

  select not exists (
    select 1
    from public.perfiles p
    where p.rol = 'admin'
      and p.activo = true
  ) into v_is_first_admin;

  if v_is_first_admin then
    v_rol := 'admin';
  end if;

  insert into public.perfiles (user_id, nombre, rol, registrado_por, editado_por)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.email),
    v_rol,
    new.id,
    new.id
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

create or replace function public.fn_es_admin()
returns boolean
language sql
stable
set search_path = public
as $$
  select exists(
    select 1
    from public.perfiles p
    where p.user_id = auth.uid()
      and p.rol = 'admin'
      and p.activo = true
  );
$$;

create or replace function public.fn_has_module(target_module text)
returns boolean
language sql
stable
set search_path = public
as $$
  select coalesce(
    public.fn_es_admin()
    or exists (
      select 1
      from public.perfiles p
      join public.role_modules rm on rm.rol = p.rol
      where p.user_id = auth.uid()
        and p.activo = true
        and rm.modulo = target_module
    ),
    false
  );
$$;

create or replace function public.fn_perfiles_set_audit()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    new.registrado_at := coalesce(new.registrado_at, now());
    new.editado_at := coalesce(new.editado_at, now());
    new.registrado_por := coalesce(new.registrado_por, auth.uid(), new.user_id);
    new.editado_por := coalesce(new.editado_por, auth.uid(), new.user_id);
  else
    if new.rol <> old.rol and not public.fn_es_admin() then
      raise exception 'Solo administradores pueden cambiar roles';
    end if;
    new.editado_at := now();
    new.editado_por := coalesce(auth.uid(), new.editado_por, old.editado_por);
  end if;
  return new;
end;
$$;

-------------------------------------------------
-- 1.3 Triggers
-------------------------------------------------

do $$
begin
  if not exists (
    select 1 from pg_trigger where tgname = 'on_auth_user_created_perfil'
  ) then
    create trigger on_auth_user_created_perfil
    after insert on auth.users
    for each row execute function public.fn_perfiles_handle_new_user();
  end if;
end;
$$;

drop trigger if exists perfiles_set_audit on public.perfiles;
create trigger perfiles_set_audit
before insert or update on public.perfiles
for each row
execute function public.fn_perfiles_set_audit();

-------------------------------------------------
-- 1.4 RLS y políticas automáticas
-------------------------------------------------

alter table public.perfiles enable row level security;

create policy perfiles_admin_full
  on public.perfiles
  for all
  using (public.fn_es_admin())
  with check (public.fn_es_admin());

create policy perfiles_self_read
  on public.perfiles
  for select
  using (auth.uid() = user_id);

create policy perfiles_self_update
  on public.perfiles
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

do $$
declare
  rec record;
  op text;
  policy_name text;
  fqname text;
  sql text;
begin
  for rec in
    select *
    from public.security_resource_modules
  loop
    fqname := format('%I.%I', rec.schema_name, rec.relation_name);
    if to_regclass(fqname) is null then
      continue;
    end if;
    execute format('alter table %I.%I enable row level security', rec.schema_name, rec.relation_name);
    for op in select unnest(rec.ops) loop
      policy_name := format('rls_%s_%s_%s', rec.modulo, rec.relation_name, op);
      execute format('drop policy if exists %I on %I.%I', policy_name, rec.schema_name, rec.relation_name);
      if op in ('insert', 'update') then
        sql := format(
          'create policy %I on %I.%I for %s using (public.fn_has_module(%L)) with check (public.fn_has_module(%L))',
          policy_name,
          rec.schema_name,
          rec.relation_name,
          op,
          rec.modulo,
          rec.modulo
        );
      else
        sql := format(
          'create policy %I on %I.%I for %s using (public.fn_has_module(%L))',
          policy_name,
          rec.schema_name,
          rec.relation_name,
          op,
          rec.modulo
        );
      end if;
      execute sql;
    end loop;
  end loop;
end;
$$;

-------------------------------------------------
-- 1.5 Grants mínimos para Supabase
-------------------------------------------------

grant usage on schema public to authenticated, anon;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage on all sequences in schema public to authenticated;

-------------------------------------------------
-- 2. MÓDULO BASES / ENTIDADES MAESTRAS
-------------------------------------------------

-- ============================================
-- TABLA: CLIENTES (versión simplificada con origen)
-- ============================================

create table if not exists clientes (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  numero text not null unique,
  canal text not null check (canal in ('telegram','referido','ads','qr')),
  referido_por uuid references clientes(id) on delete set null,
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id),
  check (canal <> 'referido' or referido_por is not null)
);



-- Direcciones de entrega asociadas a un cliente
create table if not exists direccion (
  id uuid primary key default gen_random_uuid(),
  idcliente uuid not null references clientes(id) on delete cascade,
  direccion text not null,
  referencia text,
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id)
);

-- Dirección para provincia (con datos del destinatario)
create table if not exists direccion_provincia (
  id uuid primary key default gen_random_uuid(),
  idcliente uuid not null references clientes(id) on delete cascade,
  lugar_llegada text not null,  -- dirección/destino en provincia
  nombre_completo text not null,
  dni    text not null,
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id)
);

-- Contactos que reciben el pedido (otro número/persona)
create table if not exists numrecibe (
  id uuid primary key default gen_random_uuid(),
  idcliente uuid not null references clientes(id) on delete cascade,
  numero text not null,
  nombre_contacto text,
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id)
);


-- Catálogo de categorías de productos
create table if not exists categorias (
  id uuid primary key default gen_random_uuid(),
  nombre text not null unique,        -- Ej: "Proteico", "Bowl", "Guarnición", etc.
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id)
);

-- Productos que vendes
create table if not exists productos (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  precio numeric(10,2) not null check (precio >= 0),
  idcategoria uuid references categorias(id) on delete set null,
  activo boolean default true,
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id)
);




-- Bases / hubs logísticos
create table if not exists bases (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id)
);


-------------------------------------------------
-- TABLA: LISTA_PRECIOS
-------------------------------------------------
create table if not exists lista_precios (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id)
);


-------------------------------------------------
-- TABLA: LISTA_PRECIOS_DET (escalones por producto)
-- Regla: precio_unitario = precio / cantidad_del_escalon
-------------------------------------------------
create table if not exists lista_precios_det (
  id uuid primary key default gen_random_uuid(),
  idlista uuid not null references lista_precios(id) on delete cascade,
  idproducto uuid not null references productos(id) on delete cascade,
  cantidad_escalon numeric(12,4) not null check (cantidad_escalon > 0),
  precio_unitario  numeric(12,6) not null check (precio_unitario >= 0),
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id),
  unique (idlista, idproducto, cantidad_escalon)
);


-- ============================================
-- 3. MÓDULO PEDIDOS · Pedidos (sin 'estado', con campos de auditoría)
-- ============================================

create table if not exists pedidos (
  id uuid primary key default gen_random_uuid(),
  idcliente uuid not null references clientes(id) on delete cascade,
  idlista_precios uuid references lista_precios(id),
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id),

  observacion text
);

-- ============================================
-- DETALLE DE PEDIDOS (precio venta)
-- ============================================

create table if not exists detallepedidos (
  id uuid primary key default gen_random_uuid(),
  idpedido uuid not null references pedidos(id) on delete cascade,
  idproducto uuid not null references productos(id),

  cantidad numeric(10,2) not null check (cantidad > 0),
  precioventa numeric(10,2) not null check (precioventa >= 0),

  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id),

  unique (idpedido, idproducto)  -- 1 producto por pedido (sin repetidos)
);



-------------------------------------------------
-- 4. MÓDULO OPERACIONES (Movimientos + Destinos)
-------------------------------------------------

-- Movimiento logístico (salida/entrega)
-- ============================================
-- TABLA: MOVIMIENTOS DE PEDIDOS
-- ============================================

create table if not exists movimientopedidos (
  id uuid primary key default gen_random_uuid(),
  idpedido uuid not null references pedidos(id) on delete cascade,
  idbase uuid references bases(id),
  es_provincia boolean not null default false,
  fecharegistro timestamptz default now(),
  observacion text,
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id)
);

create table if not exists mov_destino_lima (
  id uuid primary key default gen_random_uuid(),
  idmovimiento uuid not null references movimientopedidos(id) on delete cascade,
  iddireccion uuid not null references direccion(id),
  idnumrecibe uuid references numrecibe(id),   -- opcional
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id),
  unique (idmovimiento)
);

create table if not exists mov_destino_provincia (
  id uuid primary key default gen_random_uuid(),
  idmovimiento uuid not null references movimientopedidos(id) on delete cascade,
  iddir_provincia uuid not null references direccion_provincia(id),
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id),
  unique (idmovimiento)
);


-- Detalle del movimiento (qué producto y cuánto salió)
create table if not exists detallemovimientopedidos (
  id uuid primary key default gen_random_uuid(),
  idmovimiento uuid not null references movimientopedidos(id) on delete cascade,
  idproducto uuid not null references productos(id),
  cantidad numeric(10,2) not null check (cantidad > 0),
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id),
  unique (idmovimiento, idproducto)
);

-------------------------------------------------
-- 4.2 VIAJES Y ASIGNACIONES
-------------------------------------------------

create table if not exists viajes (
  id uuid primary key default gen_random_uuid(),

  -- Datos del motorizado
  nombre_motorizado text not null,
  num_llamadas text,
  num_wsp text,            -- opcional
  num_pago text,
  link text not null,
  
  monto numeric(10,2) not null check (monto >= 0),
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id)
);

-- Relación viaje ↔ movimientos (entregas efectivas)
create table if not exists viajesdetalles (
  id uuid primary key default gen_random_uuid(),
  idmovimiento uuid not null references movimientopedidos(id) on delete cascade,
  idviaje uuid not null references viajes(id) on delete cascade,
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id),
  llegada_at timestamptz,
  unique (idmovimiento)  -- << bloquea reutilizar el movimiento en otro viaje
);

-- Vista general de viajes con estado agregado
 

-------------------------------------------------
-- TABLA: INCIDENTES (1 movimiento por incidente)
-------------------------------------------------
create table if not exists incidentes (
  id uuid primary key default gen_random_uuid(),
  idmovimiento uuid not null references movimientopedidos(id) on delete cascade,
  categoria   text not null,   -- texto libre
  observacion text,
  culpa_cliente boolean default false,
  culpa_base    boolean default false,
  culpa_usuario boolean default false,
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id)
);

-------------------------------------------------
-- 5. MÓDULO FINANZAS (Pagos, Cuentas y Cargos)
-------------------------------------------------

-- Catálogo de cuentas bancarias y medios de cobro
create table if not exists cuentas_bancarias (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,         -- Ej: "Cuenta Yape", "Interbank Principal", "BCP Secundaria"
  banco text not null,          -- Ej: "Yape", "Interbank", "BBVA", "BCP", "Plin"
  activa boolean default true,
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id)
);

-- Pagos asociados al pedido
create table if not exists pagos (
  id uuid primary key default gen_random_uuid(),
  idpedido uuid not null references pedidos(id) on delete cascade,
  idcuenta uuid references cuentas_bancarias(id),   -- cuenta usada
  monto numeric(10,2) not null check (monto >= 0),
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id),
  fechapago timestamptz not null                 -- cuándo se pagó efectivamente
);

create table if not exists gastos_operativos (
  id uuid primary key default gen_random_uuid(),
  idpedido uuid not null references pedidos(id) on delete cascade,
  idcuenta uuid references cuentas_bancarias(id),
  tipo text not null,
  descripcion text,
  monto numeric(10,2) not null check (monto >= 0),
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id)
);

create table if not exists cargos_cliente (
  id uuid primary key default gen_random_uuid(),
  idpedido uuid not null references pedidos(id) on delete cascade,
  concepto text not null,  -- "Penalidad no recibió", "Delivery provincia", etc.
  monto numeric(10,2) not null check (monto >= 0),
  registrado_at timestamptz default now(),
  editado_at timestamptz,
  registrado_por uuid references auth.users(id),
  editado_por uuid references auth.users(id)
);





-------------------------------------------------
-- FUNCIONES / TRIGGERS PARA DETALLEPEDIDOS
-------------------------------------------------
create or replace function detallepedidos_calcular_total()
returns trigger
language plpgsql
as $$
declare
  v_idlista uuid;
  v_unit    numeric(12,6);
begin
  -- Solo proceder si hay producto y cantidad
  if new.idproducto is null or new.cantidad is null then
    return new;
  end if;

  -- 1) Lista del pedido
  select p.idlista_precios
    into v_idlista
  from pedidos p
  where p.id = coalesce(new.idpedido, old.idpedido);

  -- Si el pedido no tiene lista, salimos sin modificar
  if v_idlista is null then
    return new;
  end if;

  -- 2) Escalón aplicable: mayor <= cantidad; si no hay, menor disponible
  select lpd.precio_unitario
    into v_unit
  from lista_precios_det lpd
  where lpd.idlista = v_idlista
    and lpd.idproducto = new.idproducto
    and lpd.cantidad_escalon <= new.cantidad
  order by lpd.cantidad_escalon desc
  limit 1;

  if v_unit is null then
    select lpd.precio_unitario
      into v_unit
    from lista_precios_det lpd
    where lpd.idlista = v_idlista
      and lpd.idproducto = new.idproducto
    order by lpd.cantidad_escalon asc
    limit 1;
  end if;

  if v_unit is null then
    -- No hay escalones cargados para ese producto en esa lista
    return new;
  end if;

  -- 3) Calcular TOTAL = unitario * cantidad
  if tg_op = 'INSERT' then
    if new.precioventa is null then
      new.precioventa := round(v_unit * new.cantidad, 2);
    end if;
    return new;
  end if;

  if tg_op = 'UPDATE' then
    if (new.idproducto is distinct from old.idproducto)
       or (new.cantidad   is distinct from old.cantidad) then
      -- Recalcula solo si no envías un nuevo total explícito
      if new.precioventa is null or new.precioventa = old.precioventa then
        new.precioventa := round(v_unit * new.cantidad, 2);
      end if;
    end if;
    return new;
  end if;

  return new;
end;
$$;

create trigger trg_detallepedidos_calcular_total
before insert or update on detallepedidos
for each row
execute function detallepedidos_calcular_total();
-------------------------------------------------
-- FIN TABLAS MAESTRAS / INICIO VISTAS
-- (de aquí hacia abajo solo definimos vistas/reportes)
-------------------------------------------------

-------------------------------------------------
-- 6. MÓDULO REPORTES / CAPA DE CONSULTA
-------------------------------------------------

-- 6.1 Pedidos · Totales y estados básicos
-------------------------------------------------

create or replace view public.v_pedidoestadopago_detallepedido as
select  p.id as pedido_id,
        coalesce(sum(dp.precioventa), 0)::numeric(12,2) as total_pedido
from public.pedidos p
left join public.detallepedidos dp on dp.idpedido = p.id
group by p.id;

-- Total pagado por el cliente
create or replace view public.v_pedidoestadopago_pagados as
select  p.id as pedido_id,
        coalesce(sum(pg.monto), 0)::numeric(12,2) as total_pagado
from public.pedidos p
left join public.pagos pg on pg.idpedido = p.id
group by p.id;

-- Total de cargos adicionales al cliente
create or replace view public.v_pedidosestadopago_cargo as
select  p.id as pedido_id,
        coalesce(sum(cc.monto), 0)::numeric(12,2) as total_cargos_cliente
from public.pedidos p
left join public.cargos_cliente cc on cc.idpedido = p.id
group by p.id;

-- Recargo por provincia: S/ 50.00 por cada movimiento es_provincia = true
create or replace view public.v_pedidoestadopago_provincia as
with prov as (
  select m.idpedido, count(*)::int as n_movs_prov
  from public.movimientopedidos m
  where m.es_provincia = true
  group by m.idpedido
)
select  p.id as pedido_id,
        (coalesce(prov.n_movs_prov,0) * 50.00)::numeric(12,2) as total_recargo_provincia
from public.pedidos p
left join prov on prov.idpedido = p.id;


-------------------------------------------------------------
-- CAPA 2: Estado financiero/pago integrado
-------------------------------------------------------------
create or replace view public.v_pedidoestadopago as
select  p.id as pedido_id,
        p.idcliente,
        p.registrado_at as fecharegistro,
        t.total_pedido,
        cp.total_cargos_cliente,
        rp.total_recargo_provincia,
        pg.total_pagado,
        (
          coalesce(t.total_pedido,0)
        + coalesce(cp.total_cargos_cliente,0)
        + coalesce(rp.total_recargo_provincia,0)
        )::numeric(12,2) as total_con_cargos,
        (
          coalesce(t.total_pedido,0)
        + coalesce(cp.total_cargos_cliente,0)
        + coalesce(rp.total_recargo_provincia,0)
        - coalesce(pg.total_pagado,0)
        )::numeric(12,2) as saldo,
        case
          when coalesce(pg.total_pagado,0) = 0 then 'pendiente'
          when (
            coalesce(t.total_pedido,0)
          + coalesce(cp.total_cargos_cliente,0)
          + coalesce(rp.total_recargo_provincia,0)
          - coalesce(pg.total_pagado,0)
          ) = 0 then 'terminado'
          when (
            coalesce(t.total_pedido,0)
          + coalesce(cp.total_cargos_cliente,0)
          + coalesce(rp.total_recargo_provincia,0)
          - coalesce(pg.total_pagado,0)
          ) < 0 then 'pagado_demas'
          else 'parcial'
        end::text as estado_pago
from public.pedidos p
left join public.v_pedidoestadopago_detallepedido     t  on t.pedido_id  = p.id
left join public.v_pedidosestadopago_cargo            cp on cp.pedido_id = p.id
left join public.v_pedidoestadopago_provincia         rp on rp.pedido_id = p.id
left join public.v_pedidoestadopago_pagados           pg on pg.pedido_id = p.id;

-- 6.2 Pedidos · Seguimiento de envíos (unificado)
-------------------------------------------------
create or replace view public.v_pedidoestadoentrega as
with detalle_solicitado as (
  select
    dp.idpedido  as pedido_id,
    dp.idproducto,
    sum(dp.cantidad)::numeric(12,2) as cantidad
  from public.detallepedidos dp
  group by dp.idpedido, dp.idproducto
),
detalle_enviado as (
  select
    mp.idpedido  as pedido_id,
    dmp.idproducto,
    coalesce(sum(dmp.cantidad),0)::numeric(12,2) as cant_enviada
  from public.movimientopedidos mp
  join public.detallemovimientopedidos dmp
    on dmp.idmovimiento = mp.id
  group by mp.idpedido, dmp.idproducto
),
estado_producto as (
  select
    s.pedido_id,
    s.idproducto,
    s.cantidad,
    least(coalesce(e.cant_enviada,0), s.cantidad)::numeric(12,2) as cant_enviada,
    (s.cantidad - least(coalesce(e.cant_enviada,0), s.cantidad))::numeric(12,2) as resta
  from detalle_solicitado s
  left join detalle_enviado e
    on e.pedido_id  = s.pedido_id
   and e.idproducto = s.idproducto
)
select
  ep.pedido_id,
  count(*)                                    as n_items,
  sum( (ep.resta = 0)::int )                  as n_terminados,
  sum( (ep.resta = ep.cantidad)::int )        as n_pendientes,
  case
    when sum( (ep.resta = 0)::int ) = count(*) then 'terminado'
    when sum( (ep.resta = ep.cantidad)::int ) = count(*) then 'pendiente'
    else 'parcial'
  end                                         as estado_entrega
from estado_producto ep
group by ep.pedido_id;



-- 6.3 Movimientos/Viajes · Estados operativos
-------------------------------------------------
-- Movimientos en borrador (sin base)
create or replace view public.v_mov_borrador as
select m.id
from public.movimientopedidos m
where m.idbase is null;

-- Movimientos asignados (tienen al menos una fila en viajesdetalles)
create or replace view public.v_mov_asignados as
select dv.idmovimiento as id, count(*) as asignaciones
from public.viajesdetalles dv
group by dv.idmovimiento;

-- Movimientos con llegada (al menos una fila con llegada_at)
create or replace view public.v_mov_llegados as
select dv.idmovimiento as id, count(*) as llegadas
from public.viajesdetalles dv
where dv.llegada_at is not null
group by dv.idmovimiento;

-- Marcas de tiempo útiles (solo asignado/llegada)
create or replace view public.v_mov_timestamps as
select
  m.id,
  (select min(dv.registrado_at)
     from public.viajesdetalles dv
     where dv.idmovimiento = m.id) as asignado_at,
  (select min(dv.llegada_at)
     from public.viajesdetalles dv
     where dv.idmovimiento = m.id
       and dv.llegada_at is not null) as llegada_at
from public.movimientopedidos m;


create or replace view public.v_movimiento_estado as
select
  m.id,
  m.idpedido,
  /* idcliente derivado del pedido para evitar JOIN directo */
  (select p.idcliente
     from public.pedidos p
     where p.id = m.idpedido
     limit 1) as idcliente,
  m.idbase,
  case
    when m.idbase is null then 1                 -- pendiente
    when l.id is not null then 4                 -- llegado
    when a.id is not null then 3                 -- enviado
    else 2                                       -- asignado (con base, sin viaje)
  end as estado,
  case
    when m.idbase is null then 'pendiente'
    when l.id is not null then 'llegado'
    when a.id is not null then 'enviado'
    else 'asignado'
  end as estado_texto,
  t.asignado_at,
  t.llegada_at
from public.movimientopedidos m
left join public.v_mov_asignados  a on a.id = m.id
left join public.v_mov_llegados   l on l.id = m.id
left join public.v_mov_timestamps t on t.id = m.id;

-- 6.4 Pedidos · Estado general combinado
-------------------------------------------------
create or replace view public.v_pedido_estado_general as
select  p.id                                    as pedido_id,
        ep.estado_pago,
        ee.estado_entrega,
        case
          when ep.estado_pago = 'terminado' and ee.estado_entrega = 'terminado'
            then 'terminado'
          when ep.estado_pago = 'pendiente' or ee.estado_entrega = 'pendiente'
            then 'pendiente'
          else 'parcial'
        end as estado_general
from public.pedidos p
left join public.v_pedidoestadopago          ep on ep.pedido_id = p.id
left join public.v_pedidoestadoentrega       ee on ee.pedido_id = p.id;

-- 6.5 Pedidos · Vista general para UI
-------------------------------------------------
create or replace view public.v_pedido_vistageneral (
  id,
  fechapedido,
  observacion,
  idcliente,
  registrado_at,
  editado_at,
  registrado_por,
  editado_por,
  registrado_por_nombre,
  editado_por_nombre,
  cliente_nombre,
  cliente_numero,
  estado_pago,
  estado_entrega,
  estado_general
) as
select
  p.id                                     as id,
  coalesce(p.registrado_at, now())         as fechapedido,
  p.observacion                            as observacion,
  p.idcliente                              as idcliente,
  p.registrado_at                          as registrado_at,
  p.editado_at                             as editado_at,
  p.registrado_por                         as registrado_por,
  p.editado_por                            as editado_por,
  pr.nombre                                as registrado_por_nombre,
  pe.nombre                                as editado_por_nombre,
  c.nombre                                 as cliente_nombre,
  c.numero                                 as cliente_numero,
  ep.estado_pago,
  ee.estado_entrega,
  case
    when coalesce(ep.estado_pago, '') = 'terminado'
         and coalesce(ee.estado_entrega, '') = 'terminado'
      then 'terminado'
    when coalesce(ep.estado_pago, '') = 'pendiente'
         or coalesce(ee.estado_entrega, '') = 'pendiente'
      then 'pendiente'
    else 'parcial'
  end                                      as estado_general
from public.pedidos p
left join public.clientes                   c  on c.id = p.idcliente
left join public.perfiles                   pr on pr.user_id = p.registrado_por
left join public.perfiles                   pe on pe.user_id = p.editado_por
left join public.v_pedidoestadopago         ep on ep.pedido_id = p.id
left join public.v_pedidoestadoentrega      ee on ee.pedido_id = p.id;

-- 6.6 Movimientos · Resumen enriquecido
-------------------------------------------------
create or replace view public.v_movimiento_resumen as
select
  m.id,
  m.idpedido,
  m.fecharegistro,
  m.es_provincia,
  case
    when m.idbase is null then 'pendiente'
    when l.id is not null then 'llegado'
    when a.id is not null then 'enviado'
    else 'asignado'
  end as estado_texto,
  case
    when m.idbase is null then 1
    when l.id is not null then 4
    when a.id is not null then 3
    else 2
  end as estado_codigo,
  t.asignado_at,
  t.llegada_at,
  m.observacion                            as observacion,
  c.nombre                                  as cliente_nombre,
  case
    when m.es_provincia then null
    else coalesce(nr.numero, c.numero)
  end                                       as contacto_numero,
  case
    when m.es_provincia then null
    else d.direccion
  end                                       as direccion_texto,
  case
    when m.es_provincia then null
    else d.referencia
  end                                       as direccion_referencia,
  dp.lugar_llegada                          as provincia_destino,
  dp.nombre_completo                        as provincia_destinatario,
  dp.dni                                    as provincia_dni,
  b.nombre                                  as base_nombre
from public.movimientopedidos m
left join public.pedidos              p   on p.id = m.idpedido
left join public.clientes             c   on c.id = p.idcliente
left join public.bases                b   on b.id = m.idbase
left join public.mov_destino_lima     mdl on mdl.idmovimiento = m.id
left join public.direccion            d   on d.id = mdl.iddireccion
left join public.numrecibe            nr  on nr.id = mdl.idnumrecibe
left join public.mov_destino_provincia mdp on mdp.idmovimiento = m.id
left join public.direccion_provincia  dp  on dp.id = mdp.iddir_provincia
left join public.v_mov_asignados      a   on a.id = m.id
left join public.v_mov_llegados       l   on l.id = m.id
left join public.v_mov_timestamps     t   on t.id = m.id;

-- 6.7 Movimientos · Vista general para UI
-------------------------------------------------
create or replace view public.v_movimiento_vistageneral as
select
  m.id,
  m.idpedido,
  m.fecharegistro,
  m.es_provincia,
  m.idbase,
  m.observacion                             as observacion,
  b.nombre                                  as base_nombre,
  p.idcliente,
  c.nombre                                  as cliente_nombre,
  c.numero                                  as cliente_numero,
  case
    when m.es_provincia then null
    else coalesce(nr.numero, c.numero)
  end                                       as contacto_numero,
  case
    when m.es_provincia then null
    else d.direccion
  end                                       as direccion_texto,
  case
    when m.es_provincia then null
    else d.referencia
  end                                       as direccion_referencia,
  dp.lugar_llegada                          as provincia_destino,
  dp.nombre_completo                        as provincia_destinatario,
  dp.dni                                    as provincia_dni,
  case
    when m.idbase is null then 'pendiente'
    when l.id is not null then 'llegado'
    when a.id is not null then 'enviado'
    else 'asignado'
  end                                          as estado_texto,
  case
    when m.idbase is null then 1
    when l.id is not null then 4
    when a.id is not null then 3
    else 2
  end                                          as estado_codigo
from public.movimientopedidos m
left join public.pedidos              p   on p.id = m.idpedido
left join public.clientes             c   on c.id = p.idcliente
left join public.bases                b   on b.id = m.idbase
left join public.mov_destino_lima     mdl on mdl.idmovimiento = m.id
left join public.direccion            d   on d.id = mdl.iddireccion
left join public.numrecibe            nr  on nr.id = mdl.idnumrecibe
left join public.mov_destino_provincia mdp on mdp.idmovimiento = m.id
left join public.direccion_provincia  dp  on dp.id = mdp.iddir_provincia
left join public.v_mov_asignados      a   on a.id = m.id
left join public.v_mov_llegados       l   on l.id = m.id;

-- 6.8 Viajes · Vista general
-------------------------------------------------
create or replace view public.v_viaje_vistageneral as
with stats as (
  select
    vd.idviaje,
    count(*)::int as total_items,
    sum((vd.llegada_at is null)::int)::int as pendientes
  from public.viajesdetalles vd
  group by vd.idviaje
)
select
  v.id,
  v.nombre_motorizado,
  v.num_llamadas,
  v.num_wsp,
  v.num_pago,
  v.link,
  v.monto,
  v.registrado_at,
  v.editado_at,
  v.registrado_por,
  v.editado_por,
  coalesce(s.total_items, 0)      as total_items,
  coalesce(s.pendientes, 0)       as pendientes,
  case
    when coalesce(s.total_items, 0) > 0 and coalesce(s.pendientes, 0) = 0
      then 'terminado'
    else 'pendiente'
  end                              as estado_texto,
  case
    when coalesce(s.total_items, 0) > 0 and coalesce(s.pendientes, 0) = 0
      then 2
    else 1
  end                              as estado_codigo
from public.viajes v
left join stats s on s.idviaje = v.id;

-- 6.9 Viajes · Detalle general
-------------------------------------------------
create or replace view public.v_viaje_detalle_vistageneral as
select
  vd.id,
  vd.idviaje,
  vd.idmovimiento,
  vd.registrado_at,
  vd.editado_at,
  vd.registrado_por,
  vd.editado_por,
  vd.llegada_at,
  m.es_provincia,
  b.nombre                             as base_nombre,
  c.nombre                             as cliente_nombre,
  c.numero                             as cliente_numero,
  coalesce(nr.numero, c.numero)        as contacto_numero,
  case
    when m.es_provincia then null
    else d.direccion
  end                                  as direccion_texto,
  case
    when m.es_provincia then null
    else d.referencia
  end                                  as direccion_referencia,
  dp.lugar_llegada                     as provincia_destino,
  dp.nombre_completo                   as provincia_destinatario,
  dp.dni                               as provincia_dni
from public.viajesdetalles vd
join public.movimientopedidos m on m.id = vd.idmovimiento
left join public.bases b on b.id = m.idbase
left join public.pedidos p on p.id = m.idpedido
left join public.clientes c on c.id = p.idcliente
left join public.mov_destino_lima     mdl on mdl.idmovimiento = m.id
left join public.direccion            d   on d.id = mdl.iddireccion
left join public.numrecibe            nr  on nr.id = mdl.idnumrecibe
left join public.mov_destino_provincia mdp on mdp.idmovimiento = m.id
left join public.direccion_provincia  dp  on dp.id = mdp.iddir_provincia;
