alter table public.profiles add column if not exists username_changed_at timestamptz, add column if not exists display_name_changed_at timestamptz;
create or replace function private.enforce_profile_name_change_cooldowns()
returns trigger language plpgsql set search_path = '' as $$
begin
 if new.username is distinct from old.username then
  if old.username_changed_at is not null and now()<old.username_changed_at+interval '14 days' then
   raise exception using errcode='23514',message='USERNAME_COOLDOWN: Puedes cambiar tu @usuario nuevamente después de cumplir 14 días desde el último cambio.';
  end if;
  new.username_changed_at:=now();
 else new.username_changed_at:=old.username_changed_at; end if;
 if new.display_name is distinct from old.display_name then
  if old.display_name_changed_at is not null and now()<old.display_name_changed_at+interval '7 days' then
   raise exception using errcode='23514',message='DISPLAY_NAME_COOLDOWN: Puedes cambiar tu nombre nuevamente después de cumplir 7 días desde el último cambio.';
  end if;
  new.display_name_changed_at:=now();
 else new.display_name_changed_at:=old.display_name_changed_at; end if;
 return new;
end; $$;
drop trigger if exists profiles_enforce_name_change_cooldowns on public.profiles;
create trigger profiles_enforce_name_change_cooldowns before update of username,display_name on public.profiles for each row execute function private.enforce_profile_name_change_cooldowns();