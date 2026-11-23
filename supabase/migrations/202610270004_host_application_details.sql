-- Additional listing details collected during owner onboarding.
alter table public.host_applications
  add column if not exists distance_km numeric(6,2) check (distance_km is null or distance_km >= 0),
  add column if not exists amenities text[] not null default '{}',
  add column if not exists rules text not null default '',
  add column if not exists cover_image text,
  add column if not exists gallery_images text[] not null default '{}';

alter table public.dormitories
  add column if not exists rules text not null default '',
  add column if not exists gallery_images text[] not null default '{}';

create or replace function public.review_host_application(p_application_id uuid,p_decision public.review_status,p_note text default '') returns uuid
language plpgsql security definer set search_path=public as $$
declare v_actor uuid:=auth.uid(); v_app public.host_applications%rowtype; v_dorm uuid;
begin
  if not public.is_super_admin() then raise exception 'super admin required' using errcode='42501'; end if;
  if p_decision not in ('approved','rejected','changes_requested') then raise exception 'invalid review decision' using errcode='22023'; end if;
  select * into v_app from public.host_applications where id=p_application_id for update;
  if not found or v_app.status<>'pending_review' then raise exception 'application not pending review' using errcode='P0002'; end if;
  if p_decision='approved' then
	insert into public.dormitories(owner_id,name,city,address,university_name,distance_km,gender,semester_price,semester_start,semester_end,amenities,cover_image,gallery_images,rules,description,approval_status,is_active)
	values(v_app.owner_id,v_app.name,v_app.city,v_app.address,v_app.university_name,v_app.distance_km,v_app.gender,v_app.semester_price,v_app.semester_start,v_app.semester_end,v_app.amenities,v_app.cover_image,v_app.gallery_images,v_app.rules,v_app.description,'approved',true)
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
