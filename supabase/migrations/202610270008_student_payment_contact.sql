-- Student-provided payment/contact details for manual booking coordination.
alter table public.host_applications drop constraint if exists host_applications_kaspi_phone_required;
alter table public.dormitories drop constraint if exists dormitories_kaspi_phone_required;

drop function if exists public.request_bed_booking(uuid,date,date);

alter table public.bookings
  add column if not exists student_phone text,
  add column if not exists payment_contact text;

create or replace function public.request_bed_booking(
  p_bed_id uuid,
  p_check_in date,
  p_check_out date,
  p_payment_method text default 'on_site',
  p_payment_contact text default null
) returns uuid
language plpgsql security definer set search_path=public as $$
declare
  v_user uuid:=auth.uid(); v_dorm uuid; v_price numeric; v_gender public.dorm_gender;
  v_role public.user_role; v_booking uuid; v_term_start date; v_term_end date;
  v_student_pref public.dorm_gender; v_full_name text; v_phone text; v_email text;
  v_dorm_name text;
begin
  if v_user is null then raise exception 'authentication required' using errcode='42501'; end if;
  if p_payment_method not in ('on_site','kaspi_remote') then raise exception 'invalid payment method' using errcode='22023'; end if;
  if p_payment_method='kaspi_remote' and nullif(trim(coalesce(p_payment_contact,'')),'') is null then raise exception 'payment contact required' using errcode='22023'; end if;
  if p_check_in < current_date or p_check_in > current_date+45 or p_check_out<=p_check_in then raise exception 'invalid dates' using errcode='22023'; end if;
  select role,housing_preference,full_name,phone into v_role,v_student_pref,v_full_name,v_phone from public.profiles where id=v_user;
  if v_role is distinct from 'student' then raise exception 'student account required' using errcode='42501'; end if;
  select email into v_email from auth.users where id=v_user;
  select f.dormitory_id,coalesce(r.semester_price,d.semester_price),d.gender,d.semester_start,d.semester_end,d.name
	into v_dorm,v_price,v_gender,v_term_start,v_term_end,v_dorm_name
  from public.beds b join public.rooms r on r.id=b.room_id join public.floors f on f.id=r.floor_id join public.dormitories d on d.id=f.dormitory_id
  where b.id=p_bed_id and b.is_active and r.is_active and d.is_active and d.approval_status='approved' for update of b;
  if v_dorm is null then raise exception 'bed unavailable' using errcode='P0001'; end if;
  if p_check_in<>v_term_start or p_check_out<>v_term_end then raise exception 'booking dates must match the published semester dates' using errcode='22023'; end if;
  if v_gender<>'mixed' and (v_student_pref is null or v_student_pref not in (v_gender,'mixed')) then raise exception 'housing preference does not match this dorm type' using errcode='22023'; end if;
  insert into public.bookings(student_id,dormitory_id,bed_id,check_in,check_out,total_amount,status,payment_method,payment_recipient,student_phone,payment_contact)
  values(v_user,v_dorm,p_bed_id,p_check_in,p_check_out,v_price,'pending_review',p_payment_method,null,v_phone,nullif(trim(p_payment_contact),''))
  returning id into v_booking;
  insert into public.notifications(user_id,title,body)
  select m.user_id,'New student booking request',format('Student: %s; email: %s; phone: %s; payment contact: %s; dorm: %s',coalesce(v_full_name,'—'),coalesce(v_email,'—'),coalesce(v_phone,'—'),coalesce(nullif(trim(p_payment_contact),''),'on site'),v_dorm_name)
  from public.dorm_members m where m.dormitory_id=v_dorm;
  return v_booking;
exception when exclusion_violation then raise exception 'bed unavailable for selected dates' using errcode='23P01';
end; $$;

grant execute on function public.request_bed_booking(uuid,date,date,text,text) to authenticated;
