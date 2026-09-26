-- Proper department scoping. Previously redeem_signup_code granted every
-- staff member the top-level 'admin' role, so RLS let ANY staffer write
-- EVERY table. Now:
--   * 'admin' / 'super_admin'  = full control (unchanged for the officials)
--   * sub-roles                = full control of THEIR tables only
-- Staff helper + per-department policies, all idempotent.

-- ---------------------------------------------------------------- helper
create or replace function public.staff_role(_user_id uuid)
returns text
language sql
stable
security definer
set search_path to 'public'
as $$
  -- Returns the caller's most privileged management role:
  -- 'super_admin' > 'admin' > their single sub-role, or null.
  select case
    when exists (select 1 from public.user_roles r where r.user_id = _user_id and r.role = 'super_admin') then 'super_admin'
    when exists (select 1 from public.user_roles r where r.user_id = _user_id and r.role = 'admin') then 'admin'
    else (select r.role::text from public.user_roles r
          where r.user_id = _user_id
            and r.role in ('front_desk','kitchen','program','logistics','comms')
          limit 1)
  end
$$;

-- --------------------------------------------- kitchen (menu + orders)
drop policy if exists "Dept kitchen manages menu" on public.menu_items;
create policy "Dept kitchen manages menu"
  on public.menu_items for all to authenticated
  using (public.staff_role(auth.uid()) in ('super_admin','admin','kitchen'))
  with check (public.staff_role(auth.uid()) in ('super_admin','admin','kitchen'));

drop policy if exists "Dept kitchen manages categories" on public.menu_categories;
create policy "Dept kitchen manages categories"
  on public.menu_categories for all to authenticated
  using (public.staff_role(auth.uid()) in ('super_admin','admin','kitchen'))
  with check (public.staff_role(auth.uid()) in ('super_admin','admin','kitchen'));

drop policy if exists "Dept kitchen manages orders" on public.food_orders;
create policy "Dept kitchen manages orders"
  on public.food_orders for all to authenticated
  using (public.staff_role(auth.uid()) in ('super_admin','admin','kitchen') or auth.uid() = user_id)
  with check (public.staff_role(auth.uid()) in ('super_admin','admin','kitchen') or auth.uid() = user_id);

drop policy if exists "Dept kitchen manages order items" on public.food_order_items;
create policy "Dept kitchen manages order items"
  on public.food_order_items for all to authenticated
  using (
    public.staff_role(auth.uid()) in ('super_admin','admin','kitchen')
    or exists (select 1 from public.food_orders o where o.id = food_order_items.order_id and o.user_id = auth.uid())
  )
  with check (
    public.staff_role(auth.uid()) in ('super_admin','admin','kitchen')
    or exists (select 1 from public.food_orders o where o.id = food_order_items.order_id and o.user_id = auth.uid())
  );

-- --------------------------------------------- front desk (usher requests)
drop policy if exists "Dept front desk manages usher requests" on public.usher_requests;
create policy "Dept front desk manages usher requests"
  on public.usher_requests for all to authenticated
  using (public.staff_role(auth.uid()) in ('super_admin','admin','front_desk') or auth.uid() = user_id)
  with check (public.staff_role(auth.uid()) in ('super_admin','admin','front_desk') or auth.uid() = user_id);

-- --------------------------------------------- program (sessions + speakers)
drop policy if exists "Dept program manages sessions" on public.sessions;
create policy "Dept program manages sessions"
  on public.sessions for all to authenticated
  using (public.staff_role(auth.uid()) in ('super_admin','admin','program'))
  with check (public.staff_role(auth.uid()) in ('super_admin','admin','program'));

drop policy if exists "Dept program manages speakers" on public.speakers;
create policy "Dept program manages speakers"
  on public.speakers for all to authenticated
  using (public.staff_role(auth.uid()) in ('super_admin','admin','program'))
  with check (public.staff_role(auth.uid()) in ('super_admin','admin','program'));

drop policy if exists "Dept program manages session_speakers" on public.session_speakers;
create policy "Dept program manages session_speakers"
  on public.session_speakers for all to authenticated
  using (public.staff_role(auth.uid()) in ('super_admin','admin','program'))
  with check (public.staff_role(auth.uid()) in ('super_admin','admin','program'));

-- --------------------------------------------- logistics (hotels + emergency)
drop policy if exists "Dept logistics manages accommodations" on public.accommodations;
create policy "Dept logistics manages accommodations"
  on public.accommodations for all to authenticated
  using (public.staff_role(auth.uid()) in ('super_admin','admin','logistics'))
  with check (public.staff_role(auth.uid()) in ('super_admin','admin','logistics'));

drop policy if exists "Dept logistics manages emergency" on public.emergency_contacts;
create policy "Dept logistics manages emergency"
  on public.emergency_contacts for all to authenticated
  using (public.staff_role(auth.uid()) in ('super_admin','admin','logistics'))
  with check (public.staff_role(auth.uid()) in ('super_admin','admin','logistics'));

-- --------------------------------------------- comms (announcements)
drop policy if exists "Dept comms manages announcements" on public.announcements;
create policy "Dept comms manages announcements"
  on public.announcements for all to authenticated
  using (public.staff_role(auth.uid()) in ('super_admin','admin','comms'))
  with check (public.staff_role(auth.uid()) in ('super_admin','admin','comms'));

-- --------------------------------------------- errand requests (front desk)
drop policy if exists "Dept front desk manages errands" on public.errand_requests;
create policy "Dept front desk manages errands"
  on public.errand_requests for all to authenticated
  using (public.staff_role(auth.uid()) in ('super_admin','admin','front_desk') or auth.uid() = user_id)
  with check (public.staff_role(auth.uid()) in ('super_admin','admin','front_desk') or auth.uid() = user_id);
