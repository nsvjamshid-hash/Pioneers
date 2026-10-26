-- Supabase > SQL Editor ichida bir marta ishga tushiring.
create table profiles(
  id uuid primary key references auth.users on delete cascade,
  name text, email text, role text not null default 'user',
  xp int not null default 0, streak int not null default 0, last_day text,
  state jsonb not null default '{}', created_at timestamptz default now(), last_seen timestamptz default now());
create table activity(id bigserial primary key, uid uuid references profiles(id) on delete cascade,
  kind text, unit int, score int, total int, at timestamptz default now());
create table edits(w text primary key, data jsonb not null);
alter table profiles enable row level security;
alter table activity enable row level security;
alter table edits enable row level security;
create function my_role() returns text language sql security definer stable as $$ select role from profiles where id=auth.uid() $$;
create policy p_sel on profiles for select using (id=auth.uid() or my_role()='admin');
create policy p_upd on profiles for update using (id=auth.uid() or my_role()='admin') with check (my_role()='admin' or (id=auth.uid() and role='user'));
create policy a_ins on activity for insert with check (uid=auth.uid());
create policy a_sel on activity for select using (uid=auth.uid() or my_role()='admin');
create policy e_sel on edits for select using (true);
create policy e_all on edits for all using (my_role()='admin') with check (my_role()='admin');
create view leaderboard as select name, xp from profiles order by xp desc limit 100;
grant select on leaderboard to authenticated;
create function handle_new_user() returns trigger language plpgsql security definer as $$
begin
  insert into profiles(id,name,email,role) values(new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email,'@',1)), new.email,
    case when new.email='admin@pioneers.app' then 'admin' else 'user' end);
  return new;
end $$;
create trigger on_signup after insert on auth.users for each row execute function handle_new_user();
