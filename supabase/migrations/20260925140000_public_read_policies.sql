-- Public browsing: visitors without an account can read conference content.
-- Personal data (orders, agenda, messages, profiles) and admin writes stay behind auth.
-- Idempotent: drops the "signed-in only" read policies, then (re)creates public ones.

drop policy if exists "Anyone signed in views accommodations" on public.accommodations;
drop policy if exists "Anyone signed in views announcements" on public.announcements;
drop policy if exists "Anyone signed in views emergency" on public.emergency_contacts;
drop policy if exists "Anyone signed in views categories" on public.menu_categories;
drop policy if exists "Anyone signed in views menu items" on public.menu_items;
drop policy if exists "Anyone signed in views session_speakers" on public.session_speakers;
drop policy if exists "Anyone signed in can view sessions" on public.sessions;
drop policy if exists "Anyone signed in can view speakers" on public.speakers;

create policy "Public read access" on public.sessions            for select using (true);
create policy "Public read access" on public.speakers            for select using (true);
create policy "Public read access" on public.session_speakers    for select using (true);
create policy "Public read access" on public.accommodations      for select using (true);
create policy "Public read access" on public.announcements       for select using (true);
create policy "Public read access" on public.emergency_contacts  for select using (true);
create policy "Public read access" on public.menu_categories     for select using (true);
create policy "Public read access" on public.menu_items          for select using (true);

-- Group chat: room list is public (so guests can see what exists),
-- but individual messages stay signed-in only (attendee conversation).
drop policy if exists "Anyone signed in views rooms" on public.chat_rooms;
create policy "Public read access" on public.chat_rooms for select using (true);
