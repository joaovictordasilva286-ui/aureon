-- Execute uma vez no SQL Editor do seu projeto Supabase.
-- Cria somente as tabelas e funções do Aureon; não remove dados existentes.
begin;
create table if not exists public.aureon_profiles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 name text not null,
 state jsonb not null,
 version integer not null default 0,
 constraint aureon_state_object check (jsonb_typeof(state)='object'),
 constraint aureon_name_length check (length(name) between 1 and 120)
);
alter table public.aureon_profiles enable row level security;
drop policy if exists aureon_read_own on public.aureon_profiles;
create policy aureon_read_own on public.aureon_profiles for select to authenticated using ((select auth.uid())=user_id);
revoke all on public.aureon_profiles from anon,authenticated;
grant select on public.aureon_profiles to authenticated;

create or replace function public.get_aureon()
returns table(name text,state jsonb,version integer)
language plpgsql security definer set search_path='' as $$
declare uid uuid := auth.uid(); profile_name text;
begin
 if uid is null then raise exception 'Autenticação obrigatória'; end if;
 profile_name := left(coalesce(nullif(auth.jwt()->'user_metadata'->>'name',''),split_part(auth.jwt()->>'email','@',1),'Usuário'),120);
 insert into public.aureon_profiles(user_id,name,state)
 values(uid,profile_name,'{"transactions":[],"goals":[],"accounts":[{"id":"principal","name":"Principal","initial":0}],"budgets":{},"settings":{"theme":"dark","focus":false,"reminders":true},"chat":[]}'::jsonb)
 on conflict (user_id) do nothing;
 return query select p.name,p.state,p.version from public.aureon_profiles p where p.user_id=uid;
end $$;

create or replace function public.save_aureon(new_name text,new_state jsonb,expected_version integer)
returns integer language plpgsql security definer set search_path='' as $$
declare uid uuid := auth.uid(); next_version integer; t jsonb; g jsonb; a jsonb;
begin
 if uid is null then raise exception 'Autenticação obrigatória'; end if;
 if length(trim(new_name)) not between 1 and 120 or new_state is null or jsonb_typeof(new_state)<>'object' or octet_length(new_state::text)>2000000 then raise exception 'Dados inválidos'; end if;
 if coalesce(jsonb_typeof(new_state->'transactions'),'null')<>'array' or coalesce(jsonb_typeof(new_state->'goals'),'null')<>'array' or coalesce(jsonb_typeof(new_state->'accounts'),'null')<>'array' or coalesce(jsonb_typeof(new_state->'budgets'),'null')<>'object' or coalesce(jsonb_typeof(new_state->'settings'),'null')<>'object' or coalesce(jsonb_typeof(new_state->'chat'),'null')<>'array' then raise exception 'Estrutura inválida'; end if;
 if jsonb_array_length(new_state->'accounts')<1 or jsonb_array_length(new_state->'transactions')>10000 or jsonb_array_length(new_state->'goals')>1000 or jsonb_array_length(new_state->'chat')>100 then raise exception 'Quantidade de registros inválida'; end if;
 for a in select value from jsonb_array_elements(new_state->'accounts') loop
  if coalesce(a->>'id','')='' or coalesce(a->>'name','')='' or coalesce(a->>'initial','') !~ '^[0-9]+$' or (a->>'initial')::numeric>10000000000 then raise exception 'Conta inválida'; end if;
 end loop;
 for t in select value from jsonb_array_elements(new_state->'transactions') loop
  if coalesce(t->>'amount','') !~ '^[0-9]+$' then raise exception 'Valor inválido'; end if;
  if (t->>'amount')::numeric<=0 or (t->>'amount')::numeric>10000000000 or coalesce(t->>'type','') not in ('income','expense') or coalesce(t->>'name','')='' or length(t->>'name')>120 or coalesce(t->>'date','') !~ '^\d{4}-\d{2}-\d{2}$' then raise exception 'Movimentação inválida'; end if;
  perform (t->>'date')::date;
  if not exists(select 1 from jsonb_array_elements(new_state->'accounts') as x where x->>'id'=t->>'account') then raise exception 'Conta inexistente'; end if;
 end loop;
 for g in select value from jsonb_array_elements(new_state->'goals') loop
  if coalesce(g->>'target','') !~ '^[0-9]+$' or coalesce(g->>'saved','') !~ '^[0-9]+$' then raise exception 'Meta inválida'; end if;
  if (g->>'target')::numeric<=0 or (g->>'target')::numeric>10000000000 or (g->>'saved')::numeric>10000000000 then raise exception 'Meta inválida'; end if;
  perform (g->>'deadline')::date;
 end loop;
 update public.aureon_profiles p set name=trim(new_name),state=new_state,version=p.version+1 where p.user_id=uid and p.version=expected_version returning p.version into next_version;
 return next_version;
end $$;
revoke all on function public.get_aureon() from public,anon;
revoke all on function public.save_aureon(text,jsonb,integer) from public,anon;
grant execute on function public.get_aureon() to authenticated;
grant execute on function public.save_aureon(text,jsonb,integer) to authenticated;
commit;
