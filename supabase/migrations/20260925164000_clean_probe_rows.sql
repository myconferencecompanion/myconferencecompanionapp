-- Clean probe leftovers from security testing (titles self-identify).
delete from public.sessions where title in ('should fail', 'RLS probe');

-- ------------------------------------------------------------------
-- Days 1 & 2 programme: arrivals, registration and pre-conference.
-- Conference is Nov 28 (day 1) through Dec 4 (day 7), times in UTC.
-- ------------------------------------------------------------------
insert into public.sessions (id, day, title, description, starts_at, ends_at, room, track, session_type)
values
  ('22222222-2222-4222-8222-2222222222a1', 1, 'Delegate Arrivals & Airport Pickup',
   'Arrival of delegates at Maiduguri International Airport. Look for the NSE welcome desk — marshals in branded vests will direct you to shuttle buses bound for your hotel.',
   '2026-11-28 08:00:00+00', '2026-11-28 20:00:00+00', 'Airport Arrival Hall', 'Logistics', 'arrivals'),
  ('22222222-2222-4222-8222-2222222222a2', 1, 'Registration & Badge Collection',
   'Collect your badge, conference pack, Wi-Fi card and programme booklet. Registration desks stay open through the evening.',
   '2026-11-28 12:00:00+00', '2026-11-28 19:00:00+00', 'ICC Main Foyer', 'General', 'registration'),
  ('22222222-2222-4222-8222-2222222222a3', 1, 'Welcome Mixer (Informal)',
   'Informal meet-and-greet for early arrivals. Light refreshments served. Meet the Local Organising Committee and fellow delegates ahead of the opening.',
   '2026-11-28 18:00:00+00', '2026-11-28 21:00:00+00', 'ICC Courtyard', 'Social', 'networking'),
  ('22222222-2222-4222-8222-2222222222b1', 2, 'Registration Continues',
   'Registration desks open for arrivals. Beat the Monday rush — collect your materials early.',
   '2026-11-29 08:00:00+00', '2026-11-29 18:00:00+00', 'ICC Main Foyer', 'General', 'registration'),
  ('22222222-2222-4222-8222-2222222222b2', 2, 'Hotels Check-in Support & Shuttle Briefing',
   'Dedicated desk for hotel check-in issues. Shuttle marshals brief delegates on bus routes, pickup points and morning departure times.',
   '2026-11-29 10:00:00+00', '2026-11-29 16:00:00+00', 'ICC Main Foyer', 'Logistics', 'briefing'),
  ('22222222-2222-4222-8222-2222222222b3', 2, 'Council Meeting (By Invitation)',
   'NSE Council meeting ahead of the conference opening. Invitation only.',
   '2026-11-29 14:00:00+00', '2026-11-29 17:00:00+00', 'Executive Lounge', 'Governance', 'meeting'),
  ('22222222-2222-4222-8222-2222222222b4', 2, 'Juma''at Prayers & Free Evening',
   'Time for worship and rest ahead of the opening ceremony. Shuttle schedule resumes in the evening.',
   '2026-11-29 12:00:00+00', '2026-11-29 14:30:00+00', 'Venue Mosque', 'Social', 'worship')
on conflict (id) do nothing;
