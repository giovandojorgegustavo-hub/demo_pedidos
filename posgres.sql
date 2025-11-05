-------------------------------------------------
-- 0. CONFIGURACIÓN INICIAL
-------------------------------------------------
create extension if not exists "pgcrypto"; -- para gen_random_uuid()

-------------------------------------------------
-- 1. TABLAS MAESTRAS / ENTIDADES BASE
-------------------------------------------------

-- ============================================
-- TABLA: CLIENTES (versión simplificada con origen)
-- ============================================

create table if not exists clientes (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  numero text not null,
  -- Canal de origen: solo 'telegram' o 'referido'
  canal text not null check (canal in ('telegram','referido')),
  -- Si es 'referido', apunta al cliente que lo trajo
  referido_por uuid references clientes(id) on delete set null,
  created_at timestamptz default now()
);



-- Direcciones de entrega asociadas a un cliente
create table if not exists direccion (
  id uuid primary key default gen_random_uuid(),
  idcliente uuid not null references clientes(id) on delete cascade,
  direccion text not null,
  referencia text,
  created_at timestamptz default now()
);

-- Dirección para provincia (con datos del destinatario)
create table if not exists direccion_provincia (
  id uuid primary key default gen_random_uuid(),
  idcliente uuid not null references clientes(id) on delete cascade,
  lugar_llegada text not null,  -- dirección/destino en provincia
  destinatario_nombre text not null,
  destinatario_dni    text not null,
  created_at timestamptz default now()
);

-- Contactos que reciben el pedido (otro número/persona)
create table if not exists numrecibe (
  id uuid primary key default gen_random_uuid(),
  idcliente uuid not null references clientes(id) on delete cascade,
  numero text not null,
  nombre_contacto text,
  created_at timestamptz default now()
);


-- Catálogo de categorías de productos
create table if not exists categorias (
  id uuid primary key default gen_random_uuid(),
  nombre text not null unique,        -- Ej: "Proteico", "Bowl", "Guarnición", etc.
  created_at timestamptz default now()
);

-- Productos que vendes
create table if not exists productos (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  precio numeric(10,2) not null check (precio >= 0),
  idcategoria uuid references categorias(id) on delete set null,
  activo boolean default true,
  created_at timestamptz default now()
);




-- Bases / hubs logísticos
create table if not exists bases (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  created_at timestamptz default now()
);


-------------------------------------------------
-- TABLA: LISTA_PRECIOS
-------------------------------------------------
create table if not exists lista_precios (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  created_at timestamptz not null default now(),
  edited_by text,
  edited_at timestamptz
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

  unique (idlista, idproducto, cantidad_escalon)
);


-- ============================================
-- PEDIDOS (sin 'estado', con created_at/updated_at)
-- ============================================

create table if not exists pedidos (
  id uuid primary key default gen_random_uuid(),
  idcliente uuid not null references clientes(id) on delete cascade,
  idlista_precios uuid references lista_precios(id),
  created_at timestamptz default now(),  -- momento de creación
  updated_at timestamptz default now(),  -- úLtima modificación (actualízala desde la app)

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

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  unique (idpedido, idproducto)  -- 1 producto por pedido (sin repetidos)
);

-------------------------------------------------
-- 3. LOGÍSTICA (Movimiento + Detalle)
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
  fecharegistro timestamptz default now()
);

create table if not exists mov_destino_lima (
  id uuid primary key default gen_random_uuid(),
  idmovimiento uuid not null references movimientopedidos(id) on delete cascade,
  iddireccion uuid not null references direccion(id),
  idnumrecibe uuid references numrecibe(id),   -- opcional
  created_at timestamptz default now(),
  unique (idmovimiento)
);

create table if not exists mov_destino_provincia (
  id uuid primary key default gen_random_uuid(),
  idmovimiento uuid not null references movimientopedidos(id) on delete cascade,
  iddir_provincia uuid not null references direccion_provincia(id),
  created_at timestamptz default now(),
  unique (idmovimiento)
);


-- Detalle del movimiento (qué producto y cuánto salió)
create table if not exists detallemovimientopedidos (
  id uuid primary key default gen_random_uuid(),
  idmovimiento uuid not null references movimientopedidos(id) on delete cascade,
  idproducto uuid not null references productos(id),
  cantidad numeric(10,2) not null check (cantidad > 0),
  created_at timestamptz default now(),
  unique (idmovimiento, idproducto)
);


create table if not exists gastos_operativos (
  id uuid primary key default gen_random_uuid(),
  idpedido uuid not null references pedidos(id) on delete cascade,
  tipo text not null check (tipo in ('error','descuento','cobertura_delivery','promocion','otro')),
  descripcion text,
  monto numeric(10,2) not null check (monto >= 0),
  created_at timestamptz default now()
);

create table if not exists cargos_cliente (
  id uuid primary key default gen_random_uuid(),
  idpedido uuid not null references pedidos(id) on delete cascade,
  concepto text not null,  -- "Penalidad no recibió", "Delivery provincia", etc.
  monto numeric(10,2) not null check (monto >= 0),
  created_at timestamptz default now()
);

-------------------------------------------------
-- 4. PAGOS
-------------------------------------------------

-- Pagos asociados al pedido

create table if not exists cuentas_bancarias (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,         -- Ej: "Cuenta Yape", "Interbank Principal", "BCP Secundaria"
  banco text not null,          -- Ej: "Yape", "Interbank", "BBVA", "BCP", "Plin"
  activa boolean default true,
  created_at timestamptz default now()
);


create table if not exists pagos (
  id uuid primary key default gen_random_uuid(),
  idpedido uuid not null references pedidos(id) on delete cascade,
  idcuenta uuid references cuentas_bancarias(id),   -- cuenta usada
  monto numeric(10,2) not null check (monto >= 0),
  fecharegistro timestamptz default now(),          -- cuándo se registró
  fechapago timestamptz not null                 -- cuándo se pagó efectivamente
);




-------------------------------------------------
-- 5. MOTORIZADOS / VIAJES
-------------------------------------------------

create table if not exists viajes (
  id uuid primary key default gen_random_uuid(),

  -- Datos del motorizado
  nombre_motorizado text not null,
  num_llamadas text not null,
  num_wsp text,            -- opcional
  num_pago text not null,  -- número Yape, Plin o cuenta
  
  monto numeric(10,2),
  fecharegistro timestamptz default now(),
  fechaviaje timestamptz not null,
  check (monto is null or monto >= 0)
);

-- Relación viaje ↔ movimientos (entregas efectivas)
create table if not exists detalleviajes (
  id uuid primary key default gen_random_uuid(),
  idmovimiento uuid not null references movimientopedidos(id) on delete cascade,
  idviaje uuid not null references viajes(id) on delete cascade,
  created_at timestamptz default now(),
  llegada_at timestamptz,
  llegada_by text,
  unique (idmovimiento)  -- << bloquea reutilizar el movimiento en otro viaje
);

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
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);






-------------------------------------------------
-- FUNCIÓN TRIGGER: detallepedidos_calcular_total()
-- Reglas:
--  - SOLO calcula si NEW.idproducto IS NOT NULL y NEW.cantidad IS NOT NULL.
--  - INSERT: si 'precioventa' viene NULL, calcula total.
--  - UPDATE: si cambian 'idproducto' o 'cantidad' y ambos están presentes,
--            recalcula solo si no envías un nuevo total (precioventa NULL
--            o igual al anterior).
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


-------------------------------------------------
-- TRIGGER: aplica el cálculo de TOTAL en detallepedidos
-- (se ejecuta ANTES de INSERT/UPDATE; la función decide si calcular o no)
-------------------------------------------------
create trigger trg_detallepedidos_calcular_total
before insert or update on detallepedidos
for each row
execute function detallepedidos_calcular_total();




-------------------------------------------------------------
-- CAPA 1: Totales básicos
-------------------------------------------------------------

-- Total del pedido (suma de detalle)
create or replace view public.v_pedido_total as
select  p.id as pedido_id,
        coalesce(sum(dp.precioventa), 0)::numeric(12,2) as total_pedido
from public.pedidos p
left join public.detallepedidos dp on dp.idpedido = p.id
group by p.id;

-- Total pagado por el cliente
create or replace view public.v_pedido_total_pagado as
select  p.id as pedido_id,
        coalesce(sum(pg.monto), 0)::numeric(12,2) as total_pagado
from public.pedidos p
left join public.pagos pg on pg.idpedido = p.id
group by p.id;

-- Total de cargos adicionales al cliente
create or replace view public.v_pedido_total_cargos_cliente as
select  p.id as pedido_id,
        coalesce(sum(cc.monto), 0)::numeric(12,2) as total_cargos_cliente
from public.pedidos p
left join public.cargos_cliente cc on cc.idpedido = p.id
group by p.id;

-- Recargo por provincia: S/ 50.00 por cada movimiento es_provincia = true
create or replace view public.v_pedido_total_recargo_provincia as
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
-- CAPA 2: Resumen financiero
-------------------------------------------------------------
create or replace view public.v_pedido_financiero_resumen as
select  p.id as pedido_id,
        p.idcliente,
        p.created_at as fecharegistro,
        t.total_pedido,
        cp.total_cargos_cliente,
        rp.total_recargo_provincia,
        pg.total_pagado,
        (
          coalesce(t.total_pedido,0)
        + coalesce(cp.total_cargos_cliente,0)
        + coalesce(rp.total_recargo_provincia,0)
        - coalesce(pg.total_pagado,0)
        )::numeric(12,2) as saldo
from public.pedidos p
left join public.v_pedido_total                   t  on t.pedido_id  = p.id
left join public.v_pedido_total_cargos_cliente    cp on cp.pedido_id = p.id
left join public.v_pedido_total_recargo_provincia rp on rp.pedido_id = p.id
left join public.v_pedido_total_pagado            pg on pg.pedido_id = p.id;


-------------------------------------------------------------
-- CAPA 3 (FINAL): Estado de pago
-------------------------------------------------------------
create or replace view public.v_pedido_estado_pago as
with base as (
  select  r.*,
          (
            coalesce(r.total_pedido,0)
          + coalesce(r.total_cargos_cliente,0)
          + coalesce(r.total_recargo_provincia,0)
          )::numeric(12,2) as total_con_cargos
  from public.v_pedido_financiero_resumen r
)
select  pedido_id,
        idcliente,
        fecharegistro,
        total_pedido,
        total_cargos_cliente,
        total_recargo_provincia,
        total_pagado,
        saldo,
        case
          when saldo = total_con_cargos then 'pendiente'
          when saldo  > 0               then 'parcial'
          else                               'terminado'
        end::text as estado_pago
from base;





-- vista de pedido entregados----------------------------

-- Solicitado por pedido+producto
create or replace view public.v_pedido_detalle_solicitado as
select
  dp.idpedido  as pedido_id,
  dp.idproducto,
  sum(dp.cantidad)::numeric(12,2) as cantidad
from public.detallepedidos dp
group by dp.idpedido, dp.idproducto;

-- Enviado por pedido+producto (suma en todos los movimientos del pedido)
create or replace view public.v_pedido_detalle_enviado as
select
  mp.idpedido  as pedido_id,
  dmp.idproducto,
  coalesce(sum(dmp.cantidad),0)::numeric(12,2) as cant_enviada
from public.movimientopedidos mp
join public.detallemovimientopedidos dmp
  on dmp.idmovimiento = mp.id
group by mp.idpedido, dmp.idproducto;



create or replace view public.v_pedido_producto_envio_estado as
select
  s.pedido_id,
  s.idproducto,
  s.cantidad,
  least(coalesce(e.cant_enviada,0), s.cantidad)::numeric(12,2) as cant_enviada,
  (s.cantidad - least(coalesce(e.cant_enviada,0), s.cantidad))::numeric(12,2) as resta,
  case
    when (s.cantidad - least(coalesce(e.cant_enviada,0), s.cantidad)) = 0 then 'terminado'
    when (s.cantidad - least(coalesce(e.cant_enviada,0), s.cantidad)) = s.cantidad then 'pendiente'
    else 'parcial'
  end as estado_producto
from public.v_pedido_detalle_solicitado s
left join public.v_pedido_detalle_enviado e
  on e.pedido_id  = s.pedido_id
 and e.idproducto = s.idproducto;



create or replace view public.v_pedido_estado_envio_global as
with agg as (
  select
    pedido_id,
    count(*)                                             as n_items,
    sum( (resta = 0)::int )                              as n_terminados,
    sum( (resta = cantidad)::int )                       as n_pendientes
  from public.v_pedido_producto_envio_estado
  group by pedido_id
)
select
  a.pedido_id,
  case
    when a.n_terminados = a.n_items then 'terminado'
    when a.n_pendientes = a.n_items then 'pendiente'
    else 'parcial'
  end as estado_entrega
from agg a;


--movimiento estados
-- Movimientos en borrador (sin base)
create or replace view public.v_mov_borrador as
select m.id
from public.movimientopedidos m
where m.idbase is null;

-- Movimientos asignados (tienen al menos una fila en detalleviajes)
create or replace view public.v_mov_asignados as
select dv.idmovimiento as id, count(*) as asignaciones
from public.detalleviajes dv
group by dv.idmovimiento;

-- Movimientos con llegada (al menos una fila con llegada_at)
create or replace view public.v_mov_llegados as
select dv.idmovimiento as id, count(*) as llegadas
from public.detalleviajes dv
where dv.llegada_at is not null
group by dv.idmovimiento;

-- Marcas de tiempo útiles (solo asignado/llegada)
create or replace view public.v_mov_timestamps as
select
  m.id,
  (select min(dv.created_at)
     from public.detalleviajes dv
     where dv.idmovimiento = m.id) as asignado_at,
  (select min(dv.llegada_at)
     from public.detalleviajes dv
     where dv.idmovimiento = m.id
       and dv.llegada_at is not null) as llegada_at,
  (select dv.llegada_by
     from public.detalleviajes dv
     where dv.idmovimiento = m.id
       and dv.llegada_at is not null
     order by dv.llegada_at asc
     limit 1) as llegada_by
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
    when m.idbase is null then 1                 -- borrador
    when l.id is not null then 4                 -- llegado
    when a.id is not null then 3                 -- asignado
    else 2                                       -- preparado
  end as estado,
  case
    when m.idbase is null then 'borrador'
    when l.id is not null then 'llegado'
    when a.id is not null then 'asignado'
    else 'preparado'
  end as estado_texto,
  t.asignado_at,
  t.llegada_at,
  t.llegada_by
from public.movimientopedidos m
left join public.v_mov_asignados  a on a.id = m.id
left join public.v_mov_llegados   l on l.id = m.id
left join public.v_mov_timestamps t on t.id = m.id;


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
left join public.v_pedido_estado_pago        ep on ep.pedido_id = p.id
left join public.v_pedido_estado_envio_global ee on ee.pedido_id = p.id;
