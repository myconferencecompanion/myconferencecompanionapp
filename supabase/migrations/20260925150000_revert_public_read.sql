-- Members-only app: revert the public-read experiment. All conference
-- content requires a signed-in user again (back to the original posture).
drop policy if exists "Public read access" on public.sessions;
drop policy if exists "Public read access" on public.speakers;
drop policy if exists "Public read access" on public.session_speakers;
drop policy if exists "Public read access" on public.accommodations;
drop policy if exists "Public read access" on public.announcements;
drop policy if exists "Public read access" on public.emergency_contacts;
drop policy if exists "Public read access" on public.menu_categories;
drop policy if exists "Public read access" on public.menu_items;
drop policy if exists "Public read access" on public.chat_rooms;

create policy "Anyone signed in can view sessions"
  on public.sessions for select to authenticated using (true);
create policy "Anyone signed in can view speakers"
  on public.speakers for select to authenticated using (true);
create policy "Anyone signed in views session_speakers"
  on public.session_speakers for select to authenticated using (true);
create policy "Anyone signed in views accommodations"
  on public.accommodations for select to authenticated using (true);
create policy "Anyone signed in views announcements"
  on public.announcements for select to authenticated using (true);
create policy "Anyone signed in views emergency"
  on public.emergency_contacts for select to authenticated using (true);
create policy "Anyone signed in views categories"
  on public.menu_categories for select to authenticated using (true);
create policy "Anyone signed in views menu items"
  on public.menu_items for select to authenticated using (true);
create policy "Anyone signed in views rooms"
  on public.chat_rooms for select to authenticated using (true);
