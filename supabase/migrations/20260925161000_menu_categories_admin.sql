-- Kitchen end-to-end: the menu_categories INSERT policy was missing, so the
-- kitchen could add items but never new sections. Allow full management.
drop policy if exists "Admins manage categories" on public.menu_categories;
create policy "Admins manage categories"
  on public.menu_categories for all
  to authenticated
  using (has_role(auth.uid(), 'admin'::public.app_role))
  with check (has_role(auth.uid(), 'admin'::public.app_role));
