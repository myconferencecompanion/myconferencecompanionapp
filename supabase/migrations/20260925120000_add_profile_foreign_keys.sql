-- Add profile foreign keys so PostgREST can embed profiles via user_id.
-- Columns already reference auth.users(id); adding a second FK to
-- public.profiles(id) (a 1:1 mirror of auth.users) lets the app do
-- profiles:user_id(display_name) embedded selects.

ALTER TABLE public.food_orders
  ADD CONSTRAINT food_orders_user_id_profiles_fkey
  FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.usher_requests
  ADD CONSTRAINT usher_requests_user_id_profiles_fkey
  FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.chat_messages
  ADD CONSTRAINT chat_messages_user_id_profiles_fkey
  FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.direct_messages
  ADD CONSTRAINT direct_messages_sender_id_profiles_fkey
  FOREIGN KEY (sender_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.direct_messages
  ADD CONSTRAINT direct_messages_recipient_id_profiles_fkey
  FOREIGN KEY (recipient_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.my_agenda
  ADD CONSTRAINT my_agenda_user_id_profiles_fkey
  FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
