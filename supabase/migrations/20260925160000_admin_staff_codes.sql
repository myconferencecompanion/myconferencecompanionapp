-- Admin power-up, part 1: staff signup codes + code management rights.
-- Five deterministic codes (safe to share on WhatsApp with team leads).

insert into public.signup_codes (code, role, label, is_active)
values
  ('NSE-FRONTDESK-2026', 'front_desk', 'Front Desk Staff', true),
  ('NSE-KITCHEN-2026',   'kitchen',     'Kitchen Staff',     true),
  ('NSE-PROGRAM-2026',   'program',     'Program Team',      true),
  ('NSE-LOGISTICS-2026', 'logistics',   'Logistics Team',    true),
  ('NSE-COMMS-2026',     'comms',       'Comms Team',        true)
on conflict (code) do nothing;

-- Admins could only SELECT codes; allow them to create/deactivate codes
-- from the Staff & Codes admin page.
drop policy if exists "Admins manage signup codes" on public.signup_codes;
create policy "Admins manage signup codes"
  on public.signup_codes for all
  to authenticated
  using (has_role(auth.uid(), 'admin'::public.app_role))
  with check (has_role(auth.uid(), 'admin'::public.app_role));
