-- The redeem function granted 'admin' to every code holder, which made RLS
-- treat every staffer as a full admin (department scoping was UI-only).
-- Staff now get ONLY their sub-role; 'admin'/'super_admin' are reserved for
-- the officials. Also revoke previously granted admin roles from sub-role
-- holders (code-granted admins), keeping the officials untouched.

create or replace function public.redeem_signup_code(_code text)
returns table(role_granted text, label text)
language plpgsql
security definer
set search_path to 'public'
as $$
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

  -- Grant ONLY the sub-role. RLS department policies give the holder full
  -- control of their own department and nothing else.
  INSERT INTO public.user_roles (user_id, role)
  VALUES (v_user, v_role::public.app_role)
  ON CONFLICT (user_id, role) DO NOTHING;

  RETURN QUERY SELECT v_role, v_label;
END;
$$;

-- One-time cleanup: strip the blanket 'admin' role from anyone who holds a
-- sub-role but no super_admin (i.e. users provisioned via codes).
delete from public.user_roles ur
where ur.role = 'admin'
  and not exists (select 1 from public.user_roles s where s.user_id = ur.user_id and s.role = 'super_admin')
  and exists (
    select 1 from public.user_roles sub
    where sub.user_id = ur.user_id
      and sub.role in ('front_desk','kitchen','program','logistics','comms')
  );
