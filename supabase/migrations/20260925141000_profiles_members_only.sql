-- The attendee directory is a members-only feature: scope the opted-in
-- profiles read policy to authenticated users (it previously applied to
-- anonymous visitors too). Own-profile read is scoped the same way.
drop policy if exists "Users can view opted-in profiles" on public.profiles;
drop policy if exists "Users can view their own profile" on public.profiles;

create policy "Users can view opted-in profiles"
  on public.profiles for select
  to authenticated
  using (networking_opt_in = true);

create policy "Users can view their own profile"
  on public.profiles for select
  to authenticated
  using (auth.uid() = id);
