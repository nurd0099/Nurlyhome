-- Public catalog access is limited to approved, active dormitories.
create policy "Public can view active approved dormitories"
on public.dormitories
for select
to anon, authenticated
using (approval_status = 'approved' and is_active = true);
