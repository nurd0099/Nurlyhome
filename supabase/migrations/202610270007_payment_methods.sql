-- Owner-selected payment instructions and immutable booking snapshot.
alter table public.host_applications
  add column if not exists payment_method text not null default 'on_site'
	check (payment_method in ('on_site','kaspi_remote')),
  add column if not exists kaspi_phone text;

alter table public.dormitories
  add column if not exists payment_method text not null default 'on_site'
	check (payment_method in ('on_site','kaspi_remote')),
  add column if not exists kaspi_phone text;

alter table public.bookings
  add column if not exists payment_method text not null default 'on_site'
	check (payment_method in ('on_site','kaspi_remote')),
  add column if not exists payment_recipient text;

alter table public.host_applications
  drop constraint if exists host_applications_kaspi_phone_required;
alter table public.host_applications
  add constraint host_applications_kaspi_phone_required
  check (payment_method = 'on_site' or nullif(trim(kaspi_phone), '') is not null);

alter table public.dormitories
  drop constraint if exists dormitories_kaspi_phone_required;
alter table public.dormitories
  add constraint dormitories_kaspi_phone_required
  check (payment_method = 'on_site' or nullif(trim(kaspi_phone), '') is not null);

create or replace function public.request_bed_booking(p_bed_id uuid,p_check_in date,p_check_out date) returns uuid
language plpgsql security definer set search_path=public as $$
declare
  v_user uuid:=auth.uid(); v_dorm uuid; v_price numeric; v_gender public.dorm_gender;
  v_role public.user_role; v_booking uuid; v_term_start date; v_term_end date;
  v_student_pref public.dorm_gender; v_payment_method text; v_kaspi_phone text;
begin
  if v_user is null then raise exception 'authentication required' using errcode='42501'; end if;
  if p_check_in < current_date or p_check_in > current_date+45 or p_check_out<=p_check_in then raise exception 'invalid dates' using errcode='22023'; end if;
  select role,housing_preference into v_role,v_student_pref from public.profiles where id=v_user;
  if v_role is distinct from 'student' then raise exception 'student account required' using errcode='42501'; end if;
  select f.dormitory_id,coalesce(r.semester_price,d.semester_price),d.gender,d.semester_start,d.semester_end,d.payment_method,d.kaspi_phone
	into v_dorm,v_price,v_gender,v_term_start,v_term_end,v_payment_method,v_kaspi_phone
  from public.beds b join public.rooms r on r.id=b.room_id join public.floors f on f.id=r.floor_id join public.dormitories d on d.id=f.dormitory_id
  where b.id=p_bed_id and b.is_active and r.is_active and d.is_active and d.approval_status='approved' for update of b;
  if v_dorm is null then raise exception 'bed unavailable' using errcode='P0001'; end if;
  if p_check_in<>v_term_start or p_check_out<>v_term_end then raise exception 'booking dates must match the published semester dates' using errcode='22023'; end if;
  if v_gender<>'mixed' and (v_student_pref is null or v_student_pref not in (v_gender,'mixed')) then raise exception 'housing preference does not match this dorm type' using errcode='22023'; end if;
  insert into public.bookings(student_id,dormitory_id,bed_id,check_in,check_out,total_amount,status,payment_method,payment_recipient)
  values(v_user,v_dorm,p_bed_id,p_check_in,p_check_out,v_price,'pending_review',v_payment_method,case when v_payment_method='kaspi_remote' then v_kaspi_phone else null end)
  returning id into v_booking;
  insert into public.notifications(user_id,title,body)
  select m.user_id,'New booking request','A student has requested a bed.' from public.dorm_members m where m.dormitory_id=v_dorm;
  return v_booking;
exception when exclusion_violation then raise exception 'bed unavailable for selected dates' using errcode='23P01';
end; $$;

grant execute on function public.request_bed_booking(uuid,date,date) to authenticated;

create or replace function public.review_host_application(p_application_id uuid,p_decision public.review_status,p_note text default '') returns uuid
language plpgsql security definer set search_path=public as $$
declare v_actor uuid:=auth.uid(); v_app public.host_applications%rowtype; v_dorm uuid;
begin
  if not public.is_super_admin() then raise exception 'super admin required' using errcode='42501'; end if;
  if p_decision not in ('approved','rejected','changes_requested') then raise exception 'invalid review decision' using errcode='22023'; end if;
  select * into v_app from public.host_applications where id=p_application_id for update;
  if not found or v_app.status<>'pending_review' then raise exception 'application not pending review' using errcode='P0002'; end if;
  if p_decision='approved' then
	insert into public.dormitories(owner_id,name,city,address,university_name,distance_km,gender,semester_price,semester_start,semester_end,amenities,cover_image,gallery_images,rules,description,payment_method,kaspi_phone,approval_status,is_active)
	values(v_app.owner_id,v_app.name,v_app.city,v_app.address,v_app.university_name,v_app.distance_km,v_app.gender,v_app.semester_price,v_app.semester_start,v_app.semester_end,v_app.amenities,v_app.cover_image,v_app.gallery_images,v_app.rules,v_app.description,v_app.payment_method,v_app.kaspi_phone,'approved',true)
	returning id into v_dorm;
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

grant execute on function public.review_host_application(uuid,public.review_status,text) to authenticated;
