-- ============================================================
-- Reset do login do administrador (Supabase > SQL Editor > New query > colar > Run)
-- Apaga a conta de login antiga e recria o cadastro do portal.
-- Depois: no site, use "Primeiro acesso? Criar minha senha".
-- Se der erro "relation public.docs does not exist", rode antes o supabase_setup.sql.
-- ============================================================
delete from auth.users where lower(email) = 'raphael.alves@usiminasmecanica.com.br';

delete from public.docs where col = 'acessos' and id = 'raphael.alves@usiminasmecanica.com.br';

insert into public.docs (col, id, data) values (
  'usuarios',
  'raphael.alves@usiminasmecanica.com.br',
  jsonb_build_object(
    'nome', 'Raphael Alves Santos',
    'email', 'raphael.alves@usiminasmecanica.com.br',
    'matricula', '', 'setor', 'Suprimentos', 'perfil', 'suprimentos', 'ativo', true,
    'criadoEm', to_char(now() at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'criadoPor', 'reset do administrador'
  )
) on conflict (col, id) do update set data = excluded.data, updated_at = now();

-- Conferência: deve mostrar 1 linha com o seu e-mail e perfil "suprimentos"
select id as email, data->>'perfil' as perfil, data->>'ativo' as ativo
from public.docs where col = 'usuarios';
