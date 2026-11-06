-- مؤونتي AI – المرحلة 2: الحسابات والمنازل والمخزون الأساسي مع RLS
-- شغّل هذا الملف كاملاً من Supabase Dashboard ← SQL Editor.

create type public.household_role as enum ('owner', 'admin', 'member', 'viewer');

-- ============ الجداول ============
create table public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create table public.households (
  id         uuid primary key default gen_random_uuid(),
  name       text not null check (char_length(name) between 1 and 80),
  currency   char(3) not null default 'JOD' check (currency ~ '^[A-Z]{3}$'),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.household_members (
  household_id uuid not null references public.households (id) on delete cascade,
  user_id      uuid not null references auth.users (id) on delete cascade,
  role         public.household_role not null default 'member',
  created_at   timestamptz not null default now(),
  primary key (household_id, user_id)
);
create index on public.household_members (user_id);

create table public.household_invites (
  id           uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  email        text not null check (email = lower(email)),
  role         public.household_role not null default 'member' check (role <> 'owner'),
  invited_by   uuid references auth.users (id) on delete set null,
  created_at   timestamptz not null default now(),
  expires_at   timestamptz not null default now() + interval '7 days',
  accepted_at  timestamptz
);
create index on public.household_invites (household_id);

-- المفاتيح المركبة (id, household_id) تمنع ربط صف بمنزل آخر.
create table public.storage_locations (
  id           uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  name         text not null check (char_length(name) between 1 and 60),
  kind         text not null default 'other'
               check (kind in ('fridge', 'freezer', 'pantry', 'cabinet', 'other')),
  created_by   uuid default auth.uid() references auth.users (id) on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz,
  unique (id, household_id)
);
create index on public.storage_locations (household_id);

create table public.categories (
  id           uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  name         text not null check (char_length(name) between 1 and 60),
  created_by   uuid default auth.uid() references auth.users (id) on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz,
  unique (id, household_id)
);
create index on public.categories (household_id);

create table public.products (
  id            uuid primary key default gen_random_uuid(),
  household_id  uuid not null references public.households (id) on delete cascade,
  name          text not null check (char_length(name) between 1 and 120),
  category_id   uuid,
  location_id   uuid,
  unit          text not null,
  min_quantity  numeric(12,3) not null default 0 check (min_quantity >= 0),
  barcode       text,
  is_favorite   boolean not null default false,
  notes         text,
  created_by    uuid default auth.uid() references auth.users (id) on delete set null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz,
  unique (id, household_id),
  foreign key (category_id, household_id) references public.categories (id, household_id),
  foreign key (location_id, household_id) references public.storage_locations (id, household_id)
);
create index on public.products (household_id);
create index on public.products (household_id, barcode) where barcode is not null;

create table public.product_batches (
  id           uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  product_id   uuid not null,
  quantity     numeric(12,3) not null check (quantity >= 0),
  purchased_on date,
  expires_on   date,
  unit_price   numeric(12,3) check (unit_price >= 0),
  is_opened    boolean not null default false,
  location_id  uuid,
  created_by   uuid default auth.uid() references auth.users (id) on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz,
  unique (id, household_id),
  foreign key (product_id, household_id) references public.products (id, household_id) on delete cascade,
  foreign key (location_id, household_id) references public.storage_locations (id, household_id)
);
create index on public.product_batches (household_id, expires_on);
create index on public.product_batches (product_id);

-- سجل حركة المخزون: للإضافة فقط (لا تعديل ولا حذف).
create table public.stock_movements (
  id           uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  product_id   uuid not null,
  batch_id     uuid,
  kind         text not null check (kind in ('purchase', 'consume', 'waste', 'adjust')),
  quantity     numeric(12,3) not null,
  note         text,
  created_by   uuid default auth.uid() references auth.users (id) on delete set null,
  created_at   timestamptz not null default now(),
  foreign key (product_id, household_id) references public.products (id, household_id) on delete cascade,
  foreign key (batch_id, household_id) references public.product_batches (id, household_id) on delete cascade
);
create index on public.stock_movements (household_id, created_at desc);

-- ============ دوال مساعدة (security definer لتفادي التكرار اللانهائي في RLS) ============
create function public.my_role(h uuid) returns public.household_role
language sql stable security definer set search_path = '' as $$
  select role from public.household_members
  where household_id = h and user_id = (select auth.uid())
$$;
create function public.is_member(h uuid) returns boolean
language sql stable security definer set search_path = '' as $$ select public.my_role(h) is not null $$;
create function public.can_write(h uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce(public.my_role(h) in ('owner', 'admin', 'member'), false) $$;
create function public.can_manage(h uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce(public.my_role(h) in ('owner', 'admin'), false) $$;
create function public.shares_household(u uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.household_members a
    join public.household_members b on a.household_id = b.household_id
    where a.user_id = (select auth.uid()) and b.user_id = u)
$$;

-- ============ المشغّلات ============
create function public.set_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end $$;

do $$
declare t text;
begin
  foreach t in array array['profiles','households','storage_locations','categories','products','product_batches'] loop
    execute format('create trigger set_updated_at before update on public.%I
                    for each row execute function public.set_updated_at()', t);
  end loop;
end $$;

-- لا يُسمح بإزالة آخر مالك (إلا عند الحذف المتسلسل لحساب أو منزل).
create function public.prevent_last_owner() returns trigger
language plpgsql set search_path = '' as $$
begin
  if pg_trigger_depth() > 1 then
    if tg_op = 'DELETE' then return old; end if;
    return new;
  end if;
  if old.role = 'owner' and (tg_op = 'DELETE' or new.role <> 'owner') then
    if not exists (select 1 from public.household_members
                   where household_id = old.household_id and role = 'owner' and user_id <> old.user_id) then
      raise exception 'cannot remove the last owner' using errcode = 'P0001';
    end if;
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end $$;
create trigger prevent_last_owner before update of role or delete on public.household_members
for each row execute function public.prevent_last_owner();

create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''));
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

-- ============ دوال التطبيق (RPC) ============
create function public.create_household(p_name text, p_currency text default 'JOD')
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := (select auth.uid());
  nm  text := btrim(p_name);
  cur text := upper(btrim(p_currency));
  hid uuid;
begin
  if uid is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  if nm is null or char_length(nm) not between 1 and 80 then
    raise exception 'invalid household name' using errcode = '22023'; end if;
  if cur !~ '^[A-Z]{3}$' then raise exception 'invalid currency' using errcode = '22023'; end if;
  if (select count(*) from public.household_members where user_id = uid and role = 'owner') >= 5 then
    raise exception 'household limit reached' using errcode = '54000'; end if;

  insert into public.households (name, currency, created_by) values (nm, cur, uid) returning id into hid;
  insert into public.household_members (household_id, user_id, role) values (hid, uid, 'owner');

  -- افتراضيات قابلة للتعديل والحذف من المستخدم
  insert into public.storage_locations (household_id, name, kind, created_by) values
    (hid, 'ثلاجة', 'fridge', uid), (hid, 'فريزر', 'freezer', uid),
    (hid, 'مخزن', 'pantry', uid),  (hid, 'خزانة المطبخ', 'cabinet', uid);
  insert into public.categories (household_id, name, created_by) values
    (hid, 'خضروات وفواكه', uid), (hid, 'ألبان وبيض', uid), (hid, 'لحوم ودواجن', uid),
    (hid, 'مخبوزات', uid), (hid, 'معلبات وحبوب', uid), (hid, 'مشروبات', uid),
    (hid, 'منظفات', uid), (hid, 'أخرى', uid);
  return hid;
end $$;

create function public.accept_invite(p_invite uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := (select auth.uid());
  mail text := lower((select auth.jwt()) ->> 'email');
  inv public.household_invites;
begin
  if uid is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  select * into inv from public.household_invites
   where id = p_invite and accepted_at is null and expires_at > now() and email = mail
   for update;
  if not found then raise exception 'invite not found or expired' using errcode = 'P0002'; end if;
  insert into public.household_members (household_id, user_id, role)
  values (inv.household_id, uid, inv.role) on conflict do nothing;
  update public.household_invites set accepted_at = now() where id = inv.id;
  return inv.household_id;
end $$;

-- ============ الصلاحيات ============
revoke all on all tables in schema public from anon;
grant select, insert, update, delete on all tables in schema public to authenticated;
revoke execute on all functions in schema public from public, anon;
grant execute on function public.my_role(uuid), public.is_member(uuid), public.can_write(uuid),
  public.can_manage(uuid), public.shares_household(uuid),
  public.create_household(text, text), public.accept_invite(uuid) to authenticated;

-- ============ RLS ============
alter table public.profiles          enable row level security;
alter table public.households        enable row level security;
alter table public.household_members enable row level security;
alter table public.household_invites enable row level security;
alter table public.storage_locations enable row level security;
alter table public.categories        enable row level security;
alter table public.products          enable row level security;
alter table public.product_batches   enable row level security;
alter table public.stock_movements   enable row level security;

create policy profiles_select on public.profiles for select to authenticated
  using (id = (select auth.uid()) or public.shares_household(id));
create policy profiles_update on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy households_select on public.households for select to authenticated
  using (public.is_member(id));
create policy households_update on public.households for update to authenticated
  using (public.can_manage(id)) with check (public.can_manage(id));

create policy members_select on public.household_members for select to authenticated
  using (public.is_member(household_id));
create policy members_update on public.household_members for update to authenticated
  using (public.my_role(household_id) = 'owner') with check (public.my_role(household_id) = 'owner');
create policy members_delete on public.household_members for delete to authenticated
  using (user_id = (select auth.uid())
         or public.my_role(household_id) = 'owner'
         or (public.my_role(household_id) = 'admin' and role <> 'owner'));

create policy invites_select on public.household_invites for select to authenticated
  using (public.can_manage(household_id));
create policy invites_insert on public.household_invites for insert to authenticated
  with check (public.can_manage(household_id) and invited_by = (select auth.uid())
              and (role in ('member', 'viewer') or public.my_role(household_id) = 'owner'));
create policy invites_delete on public.household_invites for delete to authenticated
  using (public.can_manage(household_id));

do $$
declare t text;
begin
  foreach t in array array['storage_locations','categories','products','product_batches'] loop
    execute format('create policy %1$s_select on public.%1$I for select to authenticated using (public.is_member(household_id))', t);
    execute format('create policy %1$s_insert on public.%1$I for insert to authenticated
                    with check (public.can_write(household_id) and created_by = (select auth.uid()))', t);
    execute format('create policy %1$s_update on public.%1$I for update to authenticated
                    using (public.can_write(household_id)) with check (public.can_write(household_id))', t);
    execute format('create policy %1$s_delete on public.%1$I for delete to authenticated
                    using (public.can_manage(household_id))', t);
  end loop;
end $$;

create policy movements_select on public.stock_movements for select to authenticated
  using (public.is_member(household_id));
create policy movements_insert on public.stock_movements for insert to authenticated
  with check (public.can_write(household_id) and created_by = (select auth.uid()));
