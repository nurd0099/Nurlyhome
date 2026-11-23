-- Students can read and update only their own profile row.
create policy "Users can view their own profile"
on public.profiles
for select
to authenticated
using (id = auth.uid());

create policy "Users can update their own profile"
on public.profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- Keep registration metadata and the application profile in sync.
create or replace function public.handle_new_user() returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles(
	id,
	full_name,
	phone,
	student_number,
	university,
	housing_preference,
	faculty,
	course
  )
  values(
	new.id,
	coalesce(nullif(new.raw_user_meta_data->>'fullName', ''), ''),
	nullif(new.raw_user_meta_data->>'phone', ''),
	nullif(new.raw_user_meta_data->>'studentNumber', ''),
	nullif(new.raw_user_meta_data->>'university', ''),
	case
	  when new.raw_user_meta_data->>'housingPreference' in ('women', 'men', 'mixed')
		then (new.raw_user_meta_data->>'housingPreference')::public.dorm_gender
	  else null
	end,
	nullif(new.raw_user_meta_data->>'faculty', ''),
	case
	  when new.raw_user_meta_data->>'course' ~ '^[0-9]+$'
		then (new.raw_user_meta_data->>'course')::smallint
	  else null
	end
  )
  on conflict (id) do update set
	full_name = excluded.full_name,
	phone = excluded.phone,
	student_number = excluded.student_number,
	university = excluded.university,
	housing_preference = excluded.housing_preference,
	faculty = excluded.faculty,
	course = excluded.course,
	updated_at = now();

  return new;
end;
$$;

-- Recreate the trigger so this migration also repairs databases where the
-- initial trigger was not applied.
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

-- Restore profiles for users created before this trigger was installed.
insert into public.profiles(
  id,
  full_name,
  phone,
  student_number,
  university,
  housing_preference,
  faculty,
  course
)
select
  u.id,
  coalesce(nullif(u.raw_user_meta_data->>'fullName', ''), ''),
  nullif(u.raw_user_meta_data->>'phone', ''),
  nullif(u.raw_user_meta_data->>'studentNumber', ''),
  nullif(u.raw_user_meta_data->>'university', ''),
  case
	when u.raw_user_meta_data->>'housingPreference' in ('women', 'men', 'mixed')
	  then (u.raw_user_meta_data->>'housingPreference')::public.dorm_gender
	else null
  end,
  nullif(u.raw_user_meta_data->>'faculty', ''),
  case
	when u.raw_user_meta_data->>'course' ~ '^[0-9]+$'
	  then (u.raw_user_meta_data->>'course')::smallint
	else null
  end
from auth.users u
where not exists (select 1 from public.profiles p where p.id = u.id);
