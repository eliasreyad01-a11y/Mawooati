-- نسخة لـ Supabase SQL Editor (بدون أوامر psql). تُنشئ مستخدمين وهميين داخل معاملة وتُلغيها (rollback).
-- تُنفَّذ داخل معاملة وتُلغى في النهاية (rollback).
begin;

insert into auth.users (id, email) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'alice@test.com'),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'bob@test.com');

-- ---- Alice ----
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","email":"alice@test.com","role":"authenticated"}', true);
select set_config('t.hid_a', public.create_household('بيت أليس', 'JOD')::text, true);

do $$ begin
  if (select count(*) from public.storage_locations) <> 4 then raise exception 'FAIL: default locations not seeded'; end if;
  if (select role from public.household_members) <> 'owner' then raise exception 'FAIL: creator is not owner'; end if;
  insert into public.products (household_id, name, unit) values (current_setting('t.hid_a')::uuid, 'حليب', 'liter');
end $$;
select set_config('t.loc_a', (select id::text from public.storage_locations limit 1), true);
select set_config('t.prod_a', (select id::text from public.products limit 1), true);

-- ---- Bob ----
select set_config('request.jwt.claims', '{"sub":"bbbbbbbb-0000-0000-0000-000000000002","email":"bob@test.com","role":"authenticated"}', true);
select set_config('t.hid_b', public.create_household('بيت بوب')::text, true);
select set_config('t.loc_b', (select id::text from public.storage_locations limit 1), true);

do $$
declare failed boolean;
begin
  if (select count(*) from public.products) <> 0 then raise exception 'FAIL: bob sees alice products'; end if;
  if (select count(*) from public.households) <> 1 then raise exception 'FAIL: bob sees other households'; end if;
  if (select count(*) from public.storage_locations) <> 4 then raise exception 'FAIL: bob sees alice locations'; end if;

  failed := false;
  begin insert into public.products (household_id, name, unit) values (current_setting('t.hid_a')::uuid, 'x', 'piece');
  exception when others then failed := true; end;
  if not failed then raise exception 'FAIL: bob inserted into alice household'; end if;

  update public.products set name = 'hacked' where id = current_setting('t.prod_a')::uuid;
  if found then raise exception 'FAIL: bob updated alice product'; end if;

  failed := false;
  begin insert into public.household_members (household_id, user_id, role)
        values (current_setting('t.hid_a')::uuid, 'bbbbbbbb-0000-0000-0000-000000000002', 'owner');
  exception when others then failed := true; end;
  if not failed then raise exception 'FAIL: bob self-added as member'; end if;

  failed := false;
  begin perform public.accept_invite(gen_random_uuid());
  exception when others then failed := true; end;
  if not failed then raise exception 'FAIL: accept_invite accepted random id'; end if;

  -- ربط منتج بمكان تخزين من منزل آخر (سلامة مرجعية)
  failed := false;
  begin insert into public.products (household_id, name, unit, location_id)
        values (current_setting('t.hid_b')::uuid, 'y', 'piece', current_setting('t.loc_a')::uuid);
  exception when others then failed := true; end;
  if not failed then raise exception 'FAIL: cross-household location reference allowed'; end if;
end $$;

-- ---- Alice تدعو Bob كمشاهد ----
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","email":"alice@test.com","role":"authenticated"}', true);
insert into public.household_invites (household_id, email, role, invited_by)
values (current_setting('t.hid_a')::uuid, 'bob@test.com', 'viewer', 'aaaaaaaa-0000-0000-0000-000000000001');
select set_config('t.inv', (select id::text from public.household_invites), true);

do $$
declare failed boolean;
begin
  failed := false;
  begin insert into public.household_invites (household_id, email, role, invited_by)
        values (current_setting('t.hid_a')::uuid, 'x@test.com', 'owner', 'aaaaaaaa-0000-0000-0000-000000000001');
  exception when others then failed := true; end;
  if not failed then raise exception 'FAIL: owner-role invite allowed'; end if;

  -- Alice (المالك الوحيد) لا تستطيع المغادرة
  failed := false;
  begin delete from public.household_members where household_id = current_setting('t.hid_a')::uuid;
  exception when others then failed := true; end;
  if not failed then raise exception 'FAIL: last owner removed'; end if;
end $$;

-- ---- Bob يقبل الدعوة ----
select set_config('request.jwt.claims', '{"sub":"bbbbbbbb-0000-0000-0000-000000000002","email":"bob@test.com","role":"authenticated"}', true);
select public.accept_invite(current_setting('t.inv')::uuid);

do $$
declare failed boolean;
begin
  if (select count(*) from public.products) <> 1 then raise exception 'FAIL: viewer cannot read'; end if;
  if (select count(*) from public.household_invites) <> 0 then raise exception 'FAIL: viewer sees invites'; end if;

  failed := false;
  begin insert into public.products (household_id, name, unit) values (current_setting('t.hid_a')::uuid, 'z', 'piece');
  exception when others then failed := true; end;
  if not failed then raise exception 'FAIL: viewer inserted product'; end if;

  update public.households set name = 'x' where id = current_setting('t.hid_a')::uuid;
  if found then raise exception 'FAIL: viewer renamed household'; end if;

  failed := false;
  begin perform public.accept_invite(current_setting('t.inv')::uuid);
  exception when others then failed := true; end;
  if not failed then raise exception 'FAIL: invite reused'; end if;
end $$;

-- ---- anon لا يرى شيئاً ----
select set_config('request.jwt.claims', '{"role":"anon"}', true);
reset role;
set local role anon;
do $$
declare failed boolean := false;
begin
  begin perform count(*) from public.products;
  exception when others then failed := true; end;
  if not failed then raise exception 'FAIL: anon can query products'; end if;
end $$;

reset role;
-- حذف حساب مالك يجب ألا يُعطَّل بالمشغّل (حذف متسلسل)
delete from public.households where id = current_setting('t.hid_b')::uuid;
delete from auth.users where id = 'aaaaaaaa-0000-0000-0000-000000000001';


rollback;

select 'ALL RLS TESTS PASSED' as result;
