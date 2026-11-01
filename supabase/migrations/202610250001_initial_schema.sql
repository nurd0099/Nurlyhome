-- Nurlyhome initial PostgreSQL schema (run with Supabase CLI).
create extension if not exists pgcrypto;
create extension if not exists btree_gist;

create type public.user_role as enum ('student','dorm_manager','super_admin');
create type public.review_status as enum ('draft','pending_review','changes_requested','approved','rejected','suspended');
create type public.dorm_gender as enum ('women','men','mixed');
create type public.booking_status as enum ('pending_review','approved','rejected','payment_pending','confirmed','checked_in','checked_out','cancelled');
create type public.payment_status as enum ('pending','succeeded','failed','cancelled','refunded');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.user_role not null default 'student',
  full_name text not null default '',
  phone text,
  student_number text,
  university text,
  housing_preference public.dorm_gender,
  faculty text,
  course smallint check (course between 1 and 12),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,full_name,phone,student_number,university,housing_preference,faculty,course)
 values(new.id,coalesce(new.raw_user_meta_data->>'fullName',''),new.raw_user_meta_data->>'phone',new.raw_user_meta_data->>'studentNumber',new.raw_user_meta_data->>'university',nullif(new.raw_user_meta_data->>'housingPreference','')::public.dorm_gender,new.raw_user_meta_data->>'faculty',nullif(new.raw_user_meta_data->>'course','')::smallint);
 return new;
end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create table public.host_applications (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.profiles(id) on delete cascade,
 status public.review_status not null default 'pending_review', name text not null, city text not null, address text not null,
 university_name text not null, gender public.dorm_gender not null, semester_price numeric(12,2) not null check(semester_price>0),
 semester_start date not null, semester_end date not null check(semester_end>semester_start),
 description text not null, contact_phone text not null, created_at timestamptz not null default now(),
 reviewed_at timestamptz, reviewer_id uuid references public.profiles(id), reviewer_note text, dormitory_id uuid
);

create table public.dormitories (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.profiles(id),
 name text not null, city text not null, address text not null, university_name text not null,
 distance_km numeric(6,2) check(distance_km>=0), gender public.dorm_gender not null,
 semester_price numeric(12,2) not null check(semester_price>=0), semester_start date not null, semester_end date not null check(semester_end>semester_start), rating numeric(3,2) not null default 0 check(rating between 0 and 5),
 review_count integer not null default 0 check(review_count>=0), available_beds integer not null default 0 check(available_beds>=0),
 room_count integer not null default 0 check(room_count>=0), amenities text[] not null default '{}', cover_image text,
 description text not null, approval_status public.review_status not null default 'pending_review', is_active boolean not null default false,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.host_applications add constraint host_app_dorm_fk foreign key(dormitory_id) references public.dormitories(id);

create table public.dorm_members (
 dormitory_id uuid not null references public.dormitories(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade,
 member_role text not null check(member_role in ('manager','staff')),
 created_at timestamptz not null default now(), primary key(dormitory_id,user_id)
);
create index dorm_members_user_idx on public.dorm_members(user_id);

create table public.floors (
 id uuid primary key default gen_random_uuid(), dormitory_id uuid not null references public.dormitories(id) on delete cascade,
 floor_number integer not null, unique(dormitory_id,floor_number)
);
create table public.rooms (
 id uuid primary key default gen_random_uuid(), floor_id uuid not null references public.floors(id) on delete cascade,
 room_number text not null, description text not null default '', photos text[] not null default '{}', amenities text[] not null default '{}',
 semester_price numeric(12,2) check(semester_price>=0), is_active boolean not null default true, unique(floor_id,room_number)
);
create table public.beds (
 id uuid primary key default gen_random_uuid(), room_id uuid not null references public.rooms(id) on delete cascade,
 bed_number integer not null check(bed_number>0), is_active boolean not null default true,
 closed_reason text, unique(room_id,bed_number)
);

create table public.bookings (
 id uuid primary key default gen_random_uuid(), student_id uuid not null references public.profiles(id),
 dormitory_id uuid not null references public.dormitories(id), bed_id uuid not null references public.beds(id),
 check_in date not null, check_out date not null, total_amount numeric(12,2) not null check(total_amount>0),
 currency char(3) not null default 'KZT', status public.booking_status not null default 'pending_review',
 rejection_reason text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check(check_out>check_in)
);
-- Includes pending and paid states so two concurrent requests cannot claim the same bed/date range.
alter table public.bookings add constraint prevent_bed_date_overlap
 exclude using gist (bed_id with =, daterange(check_in,check_out,'[)') with &&)
 where (status in ('pending_review','approved','payment_pending','confirmed','checked_in'));
create index bookings_student_idx on public.bookings(student_id,created_at desc);
create index bookings_dorm_idx on public.bookings(dormitory_id,status);

create table public.payments (
 id uuid primary key default gen_random_uuid(), booking_id uuid not null references public.bookings(id),
 provider text not null, provider_reference text unique, status public.payment_status not null default 'pending',
 amount numeric(12,2) not null check(amount>0), currency char(3) not null default 'KZT',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.reviews (
 id uuid primary key default gen_random_uuid(), booking_id uuid not null unique references public.bookings(id),
 student_id uuid not null references public.profiles(id), dormitory_id uuid not null references public.dormitories(id),
 rating smallint not null check(rating between 1 and 5), cleanliness smallint check(cleanliness between 1 and 5),
 conditions smallint check(conditions between 1 and 5), facilities smallint check(facilities between 1 and 5),
 text text not null check(length(text)<=4000), status text not null default 'published' check(status in ('published','hidden','under_review')),
 created_at timestamptz not null default now()
);
create table public.notifications (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 title text not null, body text not null, read_at timestamptz, created_at timestamptz not null default now()
);
create table public.audit_log (
 id bigint generated always as identity primary key, actor_id uuid references public.profiles(id),
 action text not null, entity_type text not null, entity_id uuid, details jsonb not null default '{}', created_at timestamptz not null default now()
);
create table public.payment_webhook_events (
 provider text not null, event_id text not null, received_at timestamptz not null default now(), primary key(provider,event_id)
);

create or replace function public.is_dorm_manager(target uuid) returns boolean
language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.dorm_members m where m.dormitory_id=target and m.user_id=auth.uid())
 $$;
create or replace function public.is_super_admin() returns boolean
language sql stable security definer set search_path=public as $$ select exists(select 1 from public.profiles where id=auth.uid() and role='super_admin') $$;

-- One transactional booking endpoint: validates profile, dates, approval and inventory before insert.
create or replace function public.request_bed_booking(p_bed_id uuid,p_check_in date,p_check_out date) returns uuid
language plpgsql security definer set search_path=public as $$
declare v_user uuid:=auth.uid(); v_dorm uuid; v_price numeric; v_gender public.dorm_gender; v_role public.user_role; v_booking uuid; v_term_start date; v_term_end date; v_student_pref public.dorm_gender;
begin
 if v_user is null then raise exception 'authentication required' using errcode='42501'; end if;
 if p_check_in < current_date or p_check_in > current_date+45 or p_check_out<=p_check_in then raise exception 'invalid dates' using errcode='22023'; end if;
 select role,housing_preference into v_role,v_student_pref from public.profiles where id=v_user;
 if v_role is distinct from 'student' then raise exception 'student account required' using errcode='42501'; end if;
 select f.dormitory_id,coalesce(r.semester_price,d.semester_price),d.gender,d.semester_start,d.semester_end into v_dorm,v_price,v_gender,v_term_start,v_term_end
 from public.beds b join public.rooms r on r.id=b.room_id join public.floors f on f.id=r.floor_id join public.dormitories d on d.id=f.dormitory_id
 where b.id=p_bed_id and b.is_active and r.is_active and d.is_active and d.approval_status='approved' for update of b;
 if v_dorm is null then raise exception 'bed unavailable' using errcode='P0001'; end if;
 if p_check_in<>v_term_start or p_check_out<>v_term_end then raise exception 'booking dates must match the published semester dates' using errcode='22023'; end if;
 if v_gender<>'mixed' and (v_student_pref is null or v_student_pref not in (v_gender,'mixed')) then raise exception 'housing preference does not match this dorm type' using errcode='22023'; end if;
 insert into public.bookings(student_id,dormitory_id,bed_id,check_in,check_out,total_amount,status)
 values(v_user,v_dorm,p_bed_id,p_check_in,p_check_out,v_price,'pending_review') returning id into v_booking;
 insert into public.notifications(user_id,title,body) select m.user_id,'New booking request','A student has requested a bed.' from public.dorm_members m where m.dormitory_id=v_dorm;
 return v_booking;
exception when exclusion_violation then raise exception 'bed unavailable for selected dates' using errcode='23P01';
end; $$;

-- Public, date-aware availability list; occupied and closed beds are never returned.
create or replace function public.list_available_beds(p_dorm_id uuid,p_check_in date,p_check_out date)
returns table(bed_id uuid,floor_number integer,room_number text,bed_number integer,semester_price numeric,room_amenities text[])
language sql stable security invoker set search_path=public as $$
 select b.id,f.floor_number,r.room_number,b.bed_number,coalesce(r.semester_price,d.semester_price),r.amenities
 from public.beds b join public.rooms r on r.id=b.room_id join public.floors f on f.id=r.floor_id join public.dormitories d on d.id=f.dormitory_id
 where d.id=p_dorm_id and d.is_active and d.approval_status='approved' and b.is_active and r.is_active
 and p_check_out>p_check_in and p_check_in=d.semester_start and p_check_out=d.semester_end and not exists(select 1 from public.bookings x where x.bed_id=b.id and x.status in('pending_review','approved','payment_pending','confirmed','checked_in') and daterange(x.check_in,x.check_out,'[)') && daterange(p_check_in,p_check_out,'[)'))
 order by f.floor_number,r.room_number,b.bed_number;
 $$;

-- Trusted platform review provisions the public listing and manager membership atomically.
create or replace function public.review_host_application(p_application_id uuid,p_decision public.review_status,p_note text default '') returns uuid
language plpgsql security definer set search_path=public as $$
declare v_actor uuid:=auth.uid(); v_app public.host_applications%rowtype; v_dorm uuid;
begin
 if not public.is_super_admin() then raise exception 'super admin required' using errcode='42501'; end if;
 if p_decision not in ('approved','rejected','changes_requested') then raise exception 'invalid review decision' using errcode='22023'; end if;
 select * into v_app from public.host_applications where id=p_application_id for update;
 if not found or v_app.status<>'pending_review' then raise exception 'application not pending review' using errcode='P0002'; end if;
 if p_decision='approved' then
  insert into public.dormitories(owner_id,name,city,address,university_name,gender,semester_price,semester_start,semester_end,description,approval_status,is_active)
  values(v_app.owner_id,v_app.name,v_app.city,v_app.address,v_app.university_name,v_app.gender,v_app.semester_price,v_app.semester_start,v_app.semester_end,v_app.description,'approved',true) returning id into v_dorm;
  insert into public.dorm_members(dormitory_id,user_id,member_role) values(v_dorm,v_app.owner_id,'manager');
  update public.profiles set role='dorm_manager' where id=v_app.owner_id and role='student';
  update public.host_applications set status='approved',reviewed_at=now(),reviewer_id=v_actor,reviewer_note=left(coalesce(p_note,''),1000),dormitory_id=v_dorm where id=p_application_id;
  insert into public.notifications(user_id,title,body) values(v_app.owner_id,'Dorm approved','Your dormitory application was approved.');
 else
  update public.host_applications set status=p_decision,reviewed_at=now(),reviewer_id=v_actor,reviewer_note=left(coalesce(p_note,''),1000) where id=p_application_id;
  insert into public.notifications(user_id,title,body) values(v_app.owner_id,'Dorm application reviewed',coalesce(nullif(p_note,''),'Please review the application status.'));
 end if;
 insert into public.audit_log(actor_id,action,entity_type,entity_id,details) values(v_actor,'review_host_application','host_application',p_application_id,jsonb_build_object('decision',p_decision,'dormitory_id',v_dorm));
 return v_dorm;
end; $$;

-- Generate a simple floor/room/bed inventory atomically for a manager.
create or replace function public.generate_dorm_inventory(p_dorm_id uuid,p_floor_count integer,p_rooms_per_floor integer,p_beds_per_room integer) returns integer
language plpgsql security definer set search_path=public as $$
declare v_floor integer; v_room integer; v_bed integer; v_floor_id uuid; v_room_id uuid; v_total integer:=0;
begin
 if not public.is_dorm_manager(p_dorm_id) then raise exception 'not authorized' using errcode='42501'; end if;
 if p_floor_count not between 1 and 50 or p_rooms_per_floor not between 1 and 100 or p_beds_per_room not between 1 and 20 or p_floor_count*p_rooms_per_floor*p_beds_per_room>5000 then raise exception 'invalid inventory dimensions' using errcode='22023'; end if;
 if exists(select 1 from public.floors where dormitory_id=p_dorm_id) then raise exception 'inventory already exists; edit it manually' using errcode='23505'; end if;
 for v_floor in 1..p_floor_count loop
  insert into public.floors(dormitory_id,floor_number) values(p_dorm_id,v_floor) returning id into v_floor_id;
  for v_room in 1..p_rooms_per_floor loop
   insert into public.rooms(floor_id,room_number) values(v_floor_id,(v_floor*100+v_room)::text) returning id into v_room_id;
   for v_bed in 1..p_beds_per_room loop
    insert into public.beds(room_id,bed_number) values(v_room_id,v_bed);
    v_total:=v_total+1;
   end loop;
  end loop;
 end loop;
 update public.dormitories set room_count=p_floor_count*p_rooms_per_floor,available_beds=v_total,updated_at=now() where id=p_dorm_id;
 insert into public.audit_log(actor_id,action,entity_type,entity_id,details) values(auth.uid(),'inventory_generated','dormitory',p_dorm_id,jsonb_build_object('floors',p_floor_count,'rooms_per_floor',p_rooms_per_floor,'beds_per_room',p_beds_per_room));
 return v_total;
end; $$;

grant execute on function public.generate_dorm_inventory(uuid,integer,integer,integer) to authenticated;

-- Restrict profiles: role cannot be changed by account holder.
revoke update on public.profiles from authenticated;
grant update(full_name,phone,student_number,university,housing_preference,faculty,course,updated_at) on public.profiles to authenticated;

grant execute on function public.request_bed_booking(uuid,date,date) to authenticated;
grant execute on function public.list_available_beds(uuid,date,date) to anon,authenticated;
grant execute on function public.review_host_application(uuid,public.review_status,text) to authenticated;

enable row level security on public.profiles;
enable row level security on public.host_applications;
enable row level security on public.dormitories;
enable row level security on public.dorm_members;
enable row level security on public.floors;
enable row level security on public.rooms;
enable row level security on public.beds;
enable row level security on public.bookings;
enable row level security on public.payments;
enable row level security on public.reviews;
enable row level security on public.notifications;
enable row level security on public.audit_log;
enable row level security on public.payment_webhook_events;

create policy "Profiles visible to self or super admin" on public.profiles for select to authenticated using(id=auth.uid() or public.is_super_admin());
create policy "Users update own profile" on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
create policy "Owner creates host application" on public.host_applications for insert to authenticated with check(owner_id=auth.uid() and status='pending_review');
create policy "Owner sees own applications" on public.host_applications for select to authenticated using(owner_id=auth.uid() or public.is_super_admin());
create policy "Super admin reviews applications" on public.host_applications for update to authenticated using(public.is_super_admin()) with check(public.is_super_admin());
create policy "Approved dorms are public" on public.dormitories for select to anon,authenticated using((approval_status='approved' and is_active) or owner_id=auth.uid() or public.is_dorm_manager(id) or public.is_super_admin());
create policy "Dorm manager edits assigned dorm" on public.dormitories for update to authenticated using(public.is_dorm_manager(id) or public.is_super_admin()) with check(public.is_dorm_manager(id) or public.is_super_admin());
create policy "Super admin creates dorm" on public.dormitories for insert to authenticated with check(public.is_super_admin());
create policy "Managers read their memberships" on public.dorm_members for select to authenticated using(user_id=auth.uid() or public.is_super_admin());
create policy "Managers view inventory" on public.floors for select to anon,authenticated using(exists(select 1 from public.dormitories d where d.id=dormitory_id and d.approval_status='approved' and d.is_active) or public.is_dorm_manager(dormitory_id) or public.is_super_admin());
create policy "Managers manage floors" on public.floors for all to authenticated using(public.is_dorm_manager(dormitory_id) or public.is_super_admin()) with check(public.is_dorm_manager(dormitory_id) or public.is_super_admin());
create policy "Public active rooms" on public.rooms for select to anon,authenticated using(is_active and exists(select 1 from public.floors f join public.dormitories d on d.id=f.dormitory_id where f.id=floor_id and d.is_active and d.approval_status='approved') or exists(select 1 from public.floors f where f.id=floor_id and (public.is_dorm_manager(f.dormitory_id) or public.is_super_admin())));
create policy "Managers manage rooms" on public.rooms for all to authenticated using(exists(select 1 from public.floors f where f.id=floor_id and (public.is_dorm_manager(f.dormitory_id) or public.is_super_admin()))) with check(exists(select 1 from public.floors f where f.id=floor_id and (public.is_dorm_manager(f.dormitory_id) or public.is_super_admin())));
create policy "Public active beds" on public.beds for select to anon,authenticated using(is_active and exists(select 1 from public.rooms r join public.floors f on f.id=r.floor_id join public.dormitories d on d.id=f.dormitory_id where r.id=room_id and r.is_active and d.approval_status='approved' and d.is_active) or exists(select 1 from public.rooms r join public.floors f on f.id=r.floor_id where r.id=room_id and (public.is_dorm_manager(f.dormitory_id) or public.is_super_admin())));
create policy "Managers manage beds" on public.beds for all to authenticated using(exists(select 1 from public.rooms r join public.floors f on f.id=r.floor_id where r.id=room_id and (public.is_dorm_manager(f.dormitory_id) or public.is_super_admin()))) with check(exists(select 1 from public.rooms r join public.floors f on f.id=r.floor_id where r.id=room_id and (public.is_dorm_manager(f.dormitory_id) or public.is_super_admin())));
create policy "Student and dorm managers view bookings" on public.bookings for select to authenticated using(student_id=auth.uid() or public.is_dorm_manager(dormitory_id) or public.is_super_admin());
create policy "Student cancel own unpaid request" on public.bookings for update to authenticated using(student_id=auth.uid() and status in('pending_review','approved','payment_pending')) with check(student_id=auth.uid() and status='cancelled');
create policy "Dorm managers update booking status" on public.bookings for update to authenticated using(public.is_dorm_manager(dormitory_id) or public.is_super_admin()) with check(public.is_dorm_manager(dormitory_id) or public.is_super_admin());
create policy "Student sees own payments" on public.payments for select to authenticated using(exists(select 1 from public.bookings b where b.id=booking_id and (b.student_id=auth.uid() or public.is_dorm_manager(b.dormitory_id) or public.is_super_admin())));
create policy "Published reviews public" on public.reviews for select to anon,authenticated using(status='published' or student_id=auth.uid() or public.is_super_admin());
create policy "Student creates own review after stay" on public.reviews for insert to authenticated with check(student_id=auth.uid() and exists(select 1 from public.bookings b where b.id=booking_id and b.student_id=auth.uid() and b.status='checked_out' and b.dormitory_id=dormitory_id));
create policy "Users read own notifications" on public.notifications for select to authenticated using(user_id=auth.uid() or public.is_super_admin());
create policy "Users update own notifications" on public.notifications for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "Audit log super admin only" on public.audit_log for select to authenticated using(public.is_super_admin());
create policy "No client access to webhook ledger" on public.payment_webhook_events for all to authenticated using(false) with check(false);

-- Booking lifecycle changes are transactional and do not let clients forge payment confirmation.
create or replace function public.cancel_booking_request(p_booking_id uuid) returns void
language plpgsql security definer set search_path=public as $$
declare v_booking public.bookings%rowtype;
begin
 select * into v_booking from public.bookings where id=p_booking_id and student_id=auth.uid() for update;
 if not found then raise exception 'booking not found' using errcode='P0002'; end if;
 if v_booking.status not in ('pending_review','approved','payment_pending') then raise exception 'booking cannot be cancelled' using errcode='22023'; end if;
 if exists(select 1 from public.payments where booking_id=p_booking_id and status='succeeded') then raise exception 'paid bookings require provider refund workflow' using errcode='22023'; end if;
 update public.bookings set status='cancelled',updated_at=now() where id=p_booking_id;
 insert into public.audit_log(actor_id,action,entity_type,entity_id) values(auth.uid(),'cancel_booking','booking',p_booking_id);
end; $$;

create or replace function public.manager_update_booking(p_booking_id uuid,p_decision text,p_reason text default '') returns void
language plpgsql security definer set search_path=public as $$
declare v_booking public.bookings%rowtype; v_next public.booking_status;
begin
 select * into v_booking from public.bookings where id=p_booking_id for update;
 if not found or not public.is_dorm_manager(v_booking.dormitory_id) then raise exception 'not authorized' using errcode='42501'; end if;
 if p_decision='approve' and v_booking.status='pending_review' then v_next:='payment_pending';
 elsif p_decision='reject' and v_booking.status in ('pending_review','approved','payment_pending') then v_next:='rejected';
 elsif p_decision='check_in' and v_booking.status='confirmed' and exists(select 1 from public.payments where booking_id=p_booking_id and status='succeeded') then v_next:='checked_in';
 elsif p_decision='check_out' and v_booking.status='checked_in' then v_next:='checked_out';
 else raise exception 'invalid booking transition' using errcode='22023'; end if;
 update public.bookings set status=v_next,rejection_reason=case when v_next='rejected' then left(coalesce(p_reason,''),1000) else rejection_reason end,updated_at=now() where id=p_booking_id;
 insert into public.notifications(user_id,title,body) values(v_booking.student_id,'Booking status updated','Your booking status is now '||v_next::text||case when v_next='rejected' and coalesce(p_reason,'')<>'' then ': '||left(p_reason,500) else '' end);
 insert into public.audit_log(actor_id,action,entity_type,entity_id,details) values(auth.uid(),'booking_status_changed','booking',p_booking_id,jsonb_build_object('status',v_next));
end; $$;

revoke update on public.bookings from authenticated;
grant execute on function public.cancel_booking_request(uuid) to authenticated;
grant execute on function public.manager_update_booking(uuid,text,text) to authenticated;

-- Payment webhook and provisioning functions are server-owned. No raw card data is stored.
revoke all on public.payment_webhook_events from anon,authenticated;
revoke all on public.audit_log from anon,authenticated;
