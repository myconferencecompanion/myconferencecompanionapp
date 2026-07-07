
## 1. Rebrand to NSE Conference (Maiduguri, Borno)

Update `src/lib/event-config.ts`:
- Event name → "NSE Conference"
- Location → Maiduguri, Borno State, Nigeria
- Venue coordinates → default to a Maiduguri landmark (e.g. Multi-Purpose Indoor Sports Hall, ~11.8333° N, 13.1500° E) — you can fine-tune in the admin/config later
- Update any copy referencing the old event name on home, auth, and more screens

## 2. New convenience features

Three new sections accessible from the bottom tab / More drawer:

### a. Beckon an Usher
- Attendee taps "Call an usher" → picks reason (assistance, accessibility, lost item, other) + optional note + auto-captures their current location label (room / hall pin)
- Staff dashboard at `/admin/ushers` shows live queue, can mark `acknowledged` → `resolved`
- Realtime subscription so attendee sees status change

### b. Food menu & ordering
- Browse menu by category (Breakfast, Lunch, Dinner, Snacks, Drinks) with photos, price, description, availability toggle
- Add to cart → place order with pickup point / table number + notes
- "My orders" tab shows status (pending → preparing → ready → delivered)
- Admin manages menu items at `/admin/menu` and orders queue at `/admin/orders`

### c. Concierge errands (from accommodation)
- Categories: Laundry, Pharmacy run, Grocery, Document/print, Transport, Other
- Form: category, description, accommodation/room, urgency (normal / urgent), preferred time
- Status flow: requested → accepted → in-progress → completed
- Staff dashboard at `/admin/errands` to triage and update

All three are demo-ready (no payments). Payments hook will be added later via Stripe — leave a TODO marker in the order / errand schema (`payment_status` column reserved).

## 3. Database additions

New tables (all with RLS, GRANTs, timestamps, update triggers):
- `usher_requests` (user_id, reason, note, location_label, status, acknowledged_by, resolved_at)
- `menu_categories` (name, sort_order, is_active)
- `menu_items` (category_id, name, description, price_ngn, image_url, is_available, sort_order)
- `food_orders` (user_id, status, pickup_location, notes, total_ngn, payment_status default 'unpaid')
- `food_order_items` (order_id, menu_item_id, quantity, unit_price_ngn, item_name_snapshot)
- `errand_requests` (user_id, category, description, accommodation_id, room_number, urgency, status, assigned_to, completed_at, payment_status default 'unpaid')

RLS pattern:
- Attendees: read/insert/update own rows; read menu (public to authenticated)
- Admins: full CRUD via `has_role(uid, 'admin')`
- Realtime enabled on `usher_requests`, `food_orders`, `errand_requests`

## 4. UI additions

New routes:
- `_authenticated/concierge.tsx` — landing hub linking to Usher / Food / Errands
- `_authenticated/concierge.usher.tsx`
- `_authenticated/concierge.food.tsx` + `concierge.food.cart.tsx` + `concierge.orders.tsx`
- `_authenticated/concierge.errands.tsx` + `concierge.errands.new.tsx`
- `_authenticated/admin/ushers.tsx`, `admin/menu.tsx`, `admin/orders.tsx`, `admin/errands.tsx`

Add "Concierge" entry to More drawer and update Admin dashboard index with the 4 new management cards.

## 5. Seed demo data
- ~5 menu categories, ~20 menu items with Nigerian dishes (Jollof rice, Suya platter, Moi moi, Zobo, etc.) and unsplash/placeholder photos
- 2–3 sample usher requests, food orders, and errand requests across statuses for the demo
- Update any existing seeded copy that references the old event name

## 6. Uploading the venue vector map

After build I'll show a short how-to in chat — summary:
1. Drag-and-drop your SVG into the Lovable chat (paperclip / +)
2. I'll save it via the assets CDN and wire it into the venue map screen (`/map`) as the floor plan layer
3. If you want zoom/pan + clickable rooms, send the SVG with `id` attributes on each room `<g>` / `<path>` and I'll bind taps to room info

Supported: `.svg` (preferred for vector), or high-res `.png` / `.pdf` page export.

## Technical notes
- Server-side reads/writes via `createServerFn` with `requireSupabaseAuth`; admin actions check `has_role`
- Realtime via `supabase.channel().on('postgres_changes', …)` on the three queue tables
- Currency formatted as ₦ (NGN) using `Intl.NumberFormat('en-NG')`
- All new pages live under `_authenticated/` so the existing auth gate covers them
- No new connectors or secrets needed; Google Maps + Lovable AI keys already configured
