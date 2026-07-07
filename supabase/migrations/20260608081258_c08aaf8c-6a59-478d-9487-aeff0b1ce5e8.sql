
-- Fix RLS: authenticated role needs EXECUTE on has_role
GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated, anon;

-- Per-item quantity cap
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS max_per_item integer NOT NULL DEFAULT 1;

-- One item type per section across the board
UPDATE public.menu_categories SET max_per_order = 1;

-- Bump countable items to 4
UPDATE public.menu_items SET max_per_item = 4
WHERE lower(name) ~ '(bread|samosa|spring roll|puff[- ]?puff|meat pie|chin[- ]?chin|doughnut|donut|chops|small chops|sausage roll|gizdodo|suya stick|popcorn|cookie|cupcake|scotch egg|akara|moi[- ]?moi)';
