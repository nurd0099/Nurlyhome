-- Admin can safely archive or reactivate a dorm without deleting booking history.
create or replace function public.admin_set_dorm_active(p_dorm_id uuid, p_active boolean) returns void
language plpgsql security definer set search_path=public as $$
declare v_actor uuid:=auth.uid(); v_status public.review_status;
begin
  if not public.is_super_admin() then raise exception 'super admin required' using errcode='42501'; end if;
  if p_active then
	v_status:='approved';
  else
	v_status:='suspended';
  end if;
  update public.dormitories
  set is_active=p_active, approval_status=v_status, updated_at=now()
  where id=p_dorm_id;
  if not found then raise exception 'dormitory not found' using errcode='P0002'; end if;
  insert into public.audit_log(actor_id,action,entity_type,entity_id,details)
  values(v_actor,case when p_active then 'reactivate_dormitory' else 'archive_dormitory' end,'dormitory',p_dorm_id,jsonb_build_object('is_active',p_active));
end;
$$;

grant execute on function public.admin_set_dorm_active(uuid,boolean) to authenticated;

create policy "Admins can view all dormitories"
on public.dormitories
for select
to authenticated
using (public.is_super_admin());

create policy "Admins can view audit log"
on public.audit_log
for select
to authenticated
using (public.is_super_admin());

grant select on public.dormitories to authenticated;
grant select on public.audit_log to authenticated;
