-- Owners can submit and track their own applications.
create policy "Owners can create their own host applications"
on public.host_applications
for insert
to authenticated
with check (owner_id = auth.uid());

create policy "Owners and admins can view host applications"
on public.host_applications
for select
to authenticated
using (owner_id = auth.uid() or public.is_super_admin());
