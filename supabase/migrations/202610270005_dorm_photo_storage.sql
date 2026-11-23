-- Public images are served by URL, while writes stay scoped to the owner folder.
insert into storage.buckets (id, name, public)
values ('dorm-photos', 'dorm-photos', true)
on conflict (id) do update set public = true;

create policy "Owners can upload dorm photos"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'dorm-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Owners can delete dorm photos"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'dorm-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);
