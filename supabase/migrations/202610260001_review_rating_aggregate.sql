-- Keep public dorm ratings consistent with published, verified-stay reviews.
create or replace function public.refresh_dorm_review_stats(p_dorm_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
begin
 perform 1 from public.dormitories where id=p_dorm_id for update;
 update public.dormitories d
 set review_count=stats.review_count,
     rating=stats.rating,
     updated_at=now()
 from (
   select count(*)::integer as review_count,
          coalesce(round(avg(r.rating)::numeric,2),0)::numeric(3,2) as rating
   from public.reviews r
   where r.dormitory_id=p_dorm_id and r.status='published'
 ) stats
 where d.id=p_dorm_id;
end;
$$;

create or replace function public.sync_dorm_review_stats()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
 if tg_op='DELETE' then
   perform public.refresh_dorm_review_stats(old.dormitory_id);
   return old;
 end if;
 perform public.refresh_dorm_review_stats(new.dormitory_id);
 if tg_op='UPDATE' and old.dormitory_id is distinct from new.dormitory_id then
   perform public.refresh_dorm_review_stats(old.dormitory_id);
 end if;
 return new;
end;
$$;

create trigger reviews_refresh_dorm_stats
after insert or update or delete on public.reviews
for each row execute function public.sync_dorm_review_stats();

revoke all on function public.refresh_dorm_review_stats(uuid) from public, anon, authenticated;
revoke all on function public.sync_dorm_review_stats() from public, anon, authenticated;
