-- Phase 6: Gradebook (grading scales, grades, skill tracks). Run ONCE after migration-9. Safe to run twice.

create table if not exists public.grade_scales (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organisations(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 60),
  kind text not null check (kind in ('numeric', 'levels')),
  max_score numeric(8,2) check (max_score is null or max_score > 0),
  levels text[],                                     -- best first, e.g. {A*,A,B,C}
  created_at timestamptz not null default now(),
  check ((kind = 'numeric' and max_score is not null) or (kind = 'levels' and array_length(levels, 1) between 2 and 20))
);
create table if not exists public.assessments (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organisations(id) on delete cascade,
  scale_id uuid not null references public.grade_scales(id) on delete restrict,
  subject text not null check (char_length(subject) between 1 and 80),
  description text check (description is null or char_length(description) <= 200),
  assessed_on date not null default current_date,
  status text not null default 'draft' check (status in ('draft', 'published')),
  published_on date,
  staff_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  verified_by uuid references auth.users(id) on delete set null,
  verified_at timestamptz,
  created_at timestamptz not null default now()
);
create table if not exists public.assessment_grades (
  assessment_id uuid not null references public.assessments(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  org_id uuid not null references public.organisations(id) on delete cascade,
  score numeric(8,2) check (score is null or score >= 0),
  level text check (level is null or char_length(level) <= 40),
  comment text check (comment is null or char_length(comment) <= 300),
  primary key (assessment_id, student_id),
  check (score is not null or level is not null)
);
create table if not exists public.skill_tracks (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organisations(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 60),
  description text check (description is null or char_length(description) <= 200),
  levels text[] not null check (array_length(levels, 1) between 2 and 12),   -- lowest to highest
  created_at timestamptz not null default now()
);
create table if not exists public.skill_entries (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organisations(id) on delete cascade,
  track_id uuid not null references public.skill_tracks(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  level text not null check (char_length(level) <= 40),
  note text check (note is null or char_length(note) <= 300),
  assessed_on date not null default current_date,
  recorded_by uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create index if not exists grade_scales_org_idx on public.grade_scales (org_id);
create index if not exists assessments_org_idx on public.assessments (org_id, assessed_on);
create index if not exists assessments_scale_idx on public.assessments (scale_id);
create index if not exists assessments_staff_idx on public.assessments (staff_id);
create index if not exists assessment_grades_org_idx on public.assessment_grades (org_id);
create index if not exists assessment_grades_student_idx on public.assessment_grades (student_id);
create index if not exists skill_tracks_org_idx on public.skill_tracks (org_id);
create index if not exists skill_entries_org_idx on public.skill_entries (org_id);
create index if not exists skill_entries_track_idx on public.skill_entries (track_id, student_id);
create index if not exists skill_entries_student_idx on public.skill_entries (student_id);

alter table public.grade_scales enable row level security;
alter table public.assessments enable row level security;
alter table public.assessment_grades enable row level security;
alter table public.skill_tracks enable row level security;
alter table public.skill_entries enable row level security;

-- scales and skill tracks: everyone on the team can read, only owners and admins change them
drop policy if exists "team reads scales" on public.grade_scales;
drop policy if exists "admins manage scales" on public.grade_scales;
create policy "team reads scales" on public.grade_scales for select using (is_member(org_id));
create policy "admins manage scales" on public.grade_scales for all using (is_admin(org_id)) with check (is_admin(org_id));
drop policy if exists "team reads tracks" on public.skill_tracks;
drop policy if exists "admins manage tracks" on public.skill_tracks;
create policy "team reads tracks" on public.skill_tracks for select using (is_member(org_id));
create policy "admins manage tracks" on public.skill_tracks for all using (is_admin(org_id)) with check (is_admin(org_id));

-- grades: everyone on the team can read; the person who made them (or an admin) can change them
drop policy if exists "team reads assessments" on public.assessments;
drop policy if exists "team adds assessments" on public.assessments;
drop policy if exists "own or admin edits assessments" on public.assessments;
drop policy if exists "own or admin deletes assessments" on public.assessments;
create policy "team reads assessments" on public.assessments for select using (is_member(org_id));
create policy "team adds assessments" on public.assessments for insert with check (
  is_member(org_id) and (is_admin(org_id) or staff_id = auth.uid()) and (verified_by is null or is_admin(org_id))
  and exists (select 1 from public.grade_scales sc where sc.id = assessments.scale_id and sc.org_id = assessments.org_id));
create policy "own or admin edits assessments" on public.assessments for update
  using (is_member(org_id) and (is_admin(org_id) or staff_id = auth.uid()))
  with check (is_member(org_id) and (is_admin(org_id) or staff_id = auth.uid())
    and exists (select 1 from public.grade_scales sc where sc.id = assessments.scale_id and sc.org_id = assessments.org_id));
create policy "own or admin deletes assessments" on public.assessments for delete
  using (is_member(org_id) and (is_admin(org_id) or staff_id = auth.uid()));

-- only owners and admins can mark grades as verified
create or replace function public.guard_assessment_verify() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (new.verified_by is distinct from old.verified_by or new.verified_at is distinct from old.verified_at) and not public.is_admin(new.org_id) then
    raise exception 'Only owners and admins can verify grades';
  end if;
  return new;
end $$;
revoke execute on function public.guard_assessment_verify() from public, anon, authenticated;
drop trigger if exists assessment_verify_guard on public.assessments;
create trigger assessment_verify_guard before update on public.assessments
  for each row execute function public.guard_assessment_verify();

drop policy if exists "team reads grades" on public.assessment_grades;
drop policy if exists "own or admin adds grades" on public.assessment_grades;
drop policy if exists "own or admin edits grades" on public.assessment_grades;
drop policy if exists "own or admin deletes grades" on public.assessment_grades;
create policy "team reads grades" on public.assessment_grades for select using (is_member(org_id));
create policy "own or admin adds grades" on public.assessment_grades for insert with check (
  is_member(org_id)
  and exists (select 1 from public.assessments a where a.id = assessment_grades.assessment_id and a.org_id = assessment_grades.org_id
              and (is_admin(a.org_id) or a.staff_id = auth.uid()))
  and exists (select 1 from public.students st where st.id = assessment_grades.student_id and st.org_id = assessment_grades.org_id));
create policy "own or admin edits grades" on public.assessment_grades for update
  using (is_member(org_id) and exists (select 1 from public.assessments a where a.id = assessment_grades.assessment_id
         and (is_admin(a.org_id) or a.staff_id = auth.uid())))
  with check (is_member(org_id)
    and exists (select 1 from public.assessments a where a.id = assessment_grades.assessment_id and a.org_id = assessment_grades.org_id
                and (is_admin(a.org_id) or a.staff_id = auth.uid()))
    and exists (select 1 from public.students st where st.id = assessment_grades.student_id and st.org_id = assessment_grades.org_id));
create policy "own or admin deletes grades" on public.assessment_grades for delete
  using (is_member(org_id) and exists (select 1 from public.assessments a where a.id = assessment_grades.assessment_id
         and (is_admin(a.org_id) or a.staff_id = auth.uid())));

-- skill progress: anyone on the team can record it; the person who recorded it (or an admin) can undo it
drop policy if exists "team reads skill entries" on public.skill_entries;
drop policy if exists "team records skill entries" on public.skill_entries;
drop policy if exists "recorder or admin edits skill entries" on public.skill_entries;
drop policy if exists "recorder or admin deletes skill entries" on public.skill_entries;
create policy "team reads skill entries" on public.skill_entries for select using (is_member(org_id));
create policy "team records skill entries" on public.skill_entries for insert with check (
  is_member(org_id) and recorded_by = auth.uid()
  and exists (select 1 from public.skill_tracks t where t.id = skill_entries.track_id and t.org_id = skill_entries.org_id)
  and exists (select 1 from public.students st where st.id = skill_entries.student_id and st.org_id = skill_entries.org_id));
create policy "recorder or admin edits skill entries" on public.skill_entries for update
  using (is_member(org_id) and (recorded_by = auth.uid() or is_admin(org_id)))
  with check (is_member(org_id) and (recorded_by = auth.uid() or is_admin(org_id)));
create policy "recorder or admin deletes skill entries" on public.skill_entries for delete
  using (is_member(org_id) and (recorded_by = auth.uid() or is_admin(org_id)));
