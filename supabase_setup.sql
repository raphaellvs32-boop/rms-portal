-- ============================================================
-- Requisição de Materiais e Serviços · estrutura no Supabase
-- Rodar UMA vez: Supabase > SQL Editor > New query > colar > Run
-- ============================================================

-- 1) Tabela única de documentos (RMS, status, diligenciamento, usuários, configurações)
create table if not exists public.docs (
  col        text        not null,
  id         text        not null,
  data       jsonb       not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (col, id)
);
alter table public.docs replica identity full;
alter table public.docs enable row level security;

-- 2) Perfil de quem está logado (lido do cadastro de usuários do portal)
create or replace function public.rms_perfil() returns text
language sql stable security definer set search_path = public as $$
  select d.data->>'perfil'
  from public.docs d
  where d.col = 'usuarios'
    and d.id = lower(coalesce(auth.jwt()->>'email', ''))
    and coalesce((d.data->>'ativo')::boolean, true)
  limit 1
$$;

-- 3) Quem pode gravar o quê
create or replace function public.rms_pode(c text, op text) returns boolean
language plpgsql stable security definer set search_path = public as $$
declare p text := public.rms_perfil();
begin
  if p is null then return false; end if;                                        -- e-mail sem cadastro: nada
  if c like 'data/users/' || auth.uid()::text || '%' then return true; end if;    -- área pessoal de cada um
  if c = 'rms' then return op <> 'delete' or p = 'suprimentos'; end if;          -- todos emitem; só Suprimentos apaga
  if c in ('anexos', 'acessos') then return true; end if;
  if c in ('status', 'dilig', 'config') then return p in ('suprimentos', 'almoxarifado'); end if;
  return p = 'suprimentos';                                                      -- usuários e o resto: só Suprimentos
end
$$;

grant execute on function public.rms_perfil() to authenticated;
grant execute on function public.rms_pode(text, text) to authenticated;
grant select, insert, update, delete on public.docs to authenticated;

-- 4) Regras de acesso (somente usuários logados E cadastrados no portal)
drop policy if exists docs_ler      on public.docs;
drop policy if exists docs_inserir  on public.docs;
drop policy if exists docs_alterar  on public.docs;
drop policy if exists docs_apagar   on public.docs;
create policy docs_ler     on public.docs for select to authenticated using (public.rms_perfil() is not null);
create policy docs_inserir on public.docs for insert to authenticated with check (public.rms_pode(col, 'insert'));
create policy docs_alterar on public.docs for update to authenticated using (public.rms_pode(col, 'update')) with check (public.rms_pode(col, 'update'));
create policy docs_apagar  on public.docs for delete to authenticated using (public.rms_pode(col, 'delete'));

-- 5) Atualização em tempo real (as telas atualizam sozinhas)
do $$ begin
  alter publication supabase_realtime add table public.docs;
exception when duplicate_object then null;
end $$;

-- 6) Primeiro administrador
insert into public.docs (col, id, data) values (
  'usuarios',
  'raphael.alves@usiminasmecanica.com.br',
  jsonb_build_object(
    'nome', 'Raphael Alves Santos',
    'email', 'raphael.alves@usiminasmecanica.com.br',
    'matricula', '', 'setor', 'Suprimentos', 'perfil', 'suprimentos', 'ativo', true,
    'criadoEm', to_char(now() at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'criadoPor', 'script de instalação',
    'historico', jsonb_build_array(jsonb_build_object('em', to_char(now() at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'), 'acao', 'Administrador criado na instalação'))
  )
) on conflict (col, id) do nothing;

-- Pronto. Confira: select col, id from public.docs;
