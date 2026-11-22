-- Phase 7: Student and Parent Portal. Run ONCE after migration-10. Safe to run twice.
-- Adds: student accounts, parent codes, portal messages, and student/parent RLS policies

-- ---------- tables ----------
create table if not exists public.student_accounts (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organisations(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  email text not null check (email = lower(email)),
  password_hash text not null,
  is_active boolean not null default true,
  last_login_at timestamptz,
  created_at timestamptz not null default now(),
  unique (org_id, student_id)
);
create table if not exists public.parent_codes (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organisations(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  code char(5) not null check (char_length(code) = 5 and code ~ '^[A-Za-z0-9]{5}$'),
  email text,
  is_active boolean not null default true,
  last_used_at timestamptz,
  created_at timestamptz not null default now(),
  unique (org_id, student_id, code)
);
create table if not exists public.portal_messages (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organisations(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  subject text not null check (char_length(subject) between 1 and 120),
  body text not null,
  visibility text not null default 'both' check (visibility in ('student', 'parent', 'both')),
  is_read_student boolean not null default false,
  is_read_parent boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists public.portal_message_reads (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.portal_messages(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  reader_type text not null check (reader_type in ('student', 'parent')),
  read_at timestamptz not null default now(),
  unique (message_id, student_id, reader_type)
);

-- ---------- indexes ----------
create index if not exists student_accounts_org_idx on public.student_accounts (org_id);
create index if not exists student_accounts_student_idx on public.student_accounts (student_id);
create index if not exists parent_codes_org_idx on public.parent_codes (org_id);
create index if not exists parent_codes_student_idx on public.parent_codes (student_id);
create index if not exists portal_messages_org_idx on public.portal_messages (org_id, student_id, created_at desc);
create index if not exists portal_message_reads_student_idx on public.portal_message_reads (student_id, reader_type);

-- ---------- Row Level Security ----------
alter table public.student_accounts enable row level security;
alter table public.parent_codes enable row level security;
alter table public.portal_messages enable row level security;
alter table public.portal_message_reads enable row level security;

-- student_accounts: team manages, student can read own (via custom policy)
drop policy if exists "team manages student accounts" on public.student_accounts;
create policy "team manages student accounts" on public.student_accounts for all
  using (is_member(org_id)) with check (is_member(org_id));

-- parent_codes: team manages
drop policy if exists "team manages parent codes" on public.parent_codes;
create policy "team manages parent codes" on public.parent_codes for all
  using (is_member(org_id)) with check (is_member(org_id));

-- portal_messages: team can read/send; student/parent can read their relevant messages
drop policy if exists "team reads portal messages" on public.portal_messages;
create policy "team reads portal messages" on public.portal_messages for select using (is_member(org_id));
drop policy if exists "team sends portal messages" on public.portal_messages;
create policy "team sends portal messages" on public.portal_messages for insert with check (
  is_member(org_id) and sender_id = auth.uid()
  and exists (select 1 from public.students s where s.id = portal_messages.student_id and s.org_id = portal_messages.org_id)
);

-- portal_message_reads: team can read; student/parent can insert their own reads
drop policy if exists "team reads portal message reads" on public.portal_message_reads;
create policy "team reads portal message reads" on public.portal_message_reads for select using (is_member(org_id));
drop policy if exists "reader marks read" on public.portal_message_reads;
create policy "reader marks read" on public.portal_message_reads for insert with check (
  exists (
    select 1 from public.portal_messages m
    where m.id = portal_message_reads.message_id
      and m.student_id = portal_message_reads.student_id
      and m.org_id = (
        select org_id from public.students s where s.id = portal_message_reads.student_id
      )
  )
);

-- ---------- Helper functions for student/parent auth ----------
create or replace function public.verify_student_login(p_email text, p_password_hash text)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_student_id uuid;
  v_org_id uuid;
begin
  select sa.student_id, sa.org_id
  into v_student_id, v_org_id
  from public.student_accounts sa
  where sa.email = lower(p_email)
    and sa.password_hash = p_password_hash
    and sa.is_active = true;

  if v_student_id is null then
    return null;
  end if;

  update public.student_accounts
  set last_login_at = now()
  where student_id = v_student_id and org_id = v_org_id;

  return v_student_id;
end $$;

create or replace function public.verify_parent_code(p_code char(5))
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_student_id uuid;
begin
  select pc.student_id
  into v_student_id
  from public.parent_codes pc
  where pc.code = p_code
    and pc.is_active = true;

  if v_student_id is null then
    return null;
  end if;

  update public.parent_codes
  set last_used_at = now()
  where code = p_code;

  return v_student_id;
end $$;

revoke execute on function public.verify_student_login(text, text) from public, anon;
revoke execute on function public.verify_parent_code(char(5)) from public, anon;
grant execute on function public.verify_student_login(text, text) to authenticated;
grant execute on function public.verify_parent_code(char(5)) to authenticated;

-- ---------- Helper: generate unique 5-char alphanumeric code ----------
create or replace function public.generate_parent_code()
returns char(5)
language plpgsql security definer set search_path = public as $$
declare
  v_code char(5);
  v_chars text := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  v_attempt int := 0;
begin
  loop
    exit when v_attempt >= 10;
    v_code := '';
    for i in 1..5 loop
      v_code := v_code || substr(v_chars, floor(random() * length(v_chars)) + 1, 1);
    end loop;
    if not exists (select 1 from public.parent_codes where code = v_code) then
      return v_code;
    end if;
    v_attempt := v_attempt + 1;
  end loop;
  raise exception 'Failed to generate unique parent code';
end $$;

revoke execute on function public.generate_parent_code() from public, anon;
grant execute on function public.generate_parent_code() to authenticated;