ALTER TABLE public.menu_categories ADD COLUMN IF NOT EXISTS max_per_order integer NOT NULL DEFAULT 1;

UPDATE public.menu_categories SET max_per_order = 5 WHERE name = 'Breakfast';
UPDATE public.menu_categories SET max_per_order = 1 WHERE name = 'Lunch & Mains';
UPDATE public.menu_categories SET max_per_order = 3 WHERE name = 'Small Chops & Snacks';
UPDATE public.menu_categories SET max_per_order = 1 WHERE name = 'Drinks';
UPDATE public.menu_categories SET max_per_order = 1 WHERE name = 'Desserts';