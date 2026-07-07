
-- 1. Extend the role enum
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'super_admin';
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'front_desk';
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'kitchen';
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'program';
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'logistics';
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'comms';

-- 2. Signup codes table (role stored as TEXT to avoid same-txn enum-use issue)
CREATE TABLE public.signup_codes (
  code TEXT PRIMARY KEY,
  role TEXT NOT NULL,
  label TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT ON public.signup_codes TO authenticated;
GRANT ALL ON public.signup_codes TO service_role;

ALTER TABLE public.signup_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can read codes"
  ON public.signup_codes FOR SELECT
  TO authenticated
  USING (public.has_role(auth.uid(), 'admin'));

CREATE TRIGGER update_signup_codes_updated_at
  BEFORE UPDATE ON public.signup_codes
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 3. Redeem function: callable by any authenticated user, grants admin + sub-role
CREATE OR REPLACE FUNCTION public.redeem_signup_code(_code TEXT)
RETURNS TABLE(role_granted TEXT, label TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user UUID := auth.uid();
  v_role TEXT;
  v_label TEXT;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Must be signed in to redeem a code';
  END IF;

  SELECT sc.role, sc.label INTO v_role, v_label
  FROM public.signup_codes sc
  WHERE sc.code = _code AND sc.is_active = true;

  IF v_role IS NULL THEN
    RAISE EXCEPTION 'Invalid or inactive code';
  END IF;

  -- Grant top-level admin permission (so existing RLS keeps working)
  INSERT INTO public.user_roles (user_id, role)
  VALUES (v_user, 'admin'::public.app_role)
  ON CONFLICT (user_id, role) DO NOTHING;

  -- Grant the specific sub-role
  INSERT INTO public.user_roles (user_id, role)
  VALUES (v_user, v_role::public.app_role)
  ON CONFLICT (user_id, role) DO NOTHING;

  RETURN QUERY SELECT v_role, v_label;
END;
$$;

GRANT EXECUTE ON FUNCTION public.redeem_signup_code(TEXT) TO authenticated;
