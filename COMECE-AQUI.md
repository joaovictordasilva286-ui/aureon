# Aureon para GitHub + Vercel

Este pacote preserva a interface e funções do Aureon, com Supabase para cadastro por e-mail/senha, recuperação de senha e banco online. Não exige Python. A Vercel publica o site; Supabase guarda as contas e os registros.

## 1. Colocar no GitHub

Crie um repositório chamado `aureon-financas`. Extraia este ZIP. Envie **os arquivos e pastas de dentro de aureon-vercel**, mantendo as pastas `public` e `supabase`.

Na raiz do repositório devem aparecer `package.json`, `build.mjs` e `vercel.json`. Não envie somente `public` e não envie o ZIP fechado.

## 2. Preparar contas e banco

Crie um projeto em https://supabase.com/dashboard ou conecte Supabase pelo Marketplace da Vercel.

No projeto Supabase:

1. Abra **SQL Editor**, crie uma consulta e cole o conteúdo completo de `supabase/configurar-banco.sql`.
2. Execute com **Run**. Esse arquivo cria a tabela, as regras de acesso por usuário e as funções de leitura e salvamento.
3. No painel de conexão/API do projeto, localize a **Project URL** e a **Publishable key** (ou a chave pública legada `anon`).
4. Use esses dois valores nas variáveis da Vercel abaixo.

**Não use `service_role` nem `sb_secret_`.** O build rejeita essas chaves. A chave publicável é própria para código de navegador; o acesso aos dados é protegido no banco. Não precisa enviar senha do banco nem chave secreta ao chat.

## 3. Importar na Vercel

Na Vercel: **Add New → Project → Import** o repositório.

- Framework: **Other**.
- Root Directory: a raiz onde está `package.json`.
- Build Command: `npm run build`.
- Output Directory: `dist`.
- Adicione em **Environment Variables**, para Production e Preview:

| Nome | Valor |
|---|---|
| `SUPABASE_URL` | A Project URL do seu Supabase |
| `SUPABASE_PUBLISHABLE_KEY` | A chave publicável ou anon |

Clique em **Deploy**. O pacote não instala dependências. Sem as variáveis, o build para com uma mensagem explicativa; isso evita publicar um login quebrado. Se mudar as variáveis depois, faça um novo deploy.

## 4. Configurar os links de confirmação e recuperação

Copie o endereço final da Vercel. No Supabase, em **Authentication → URL Configuration**:

- **Site URL**: o endereço HTTPS publicado.
- **Redirect URLs**: adicione o mesmo endereço com `/` no final.

Mantenha autenticação por e-mail habilitada. A confirmação de e-mail funciona pelo link enviado pelo Supabase. O usuário deve entrar depois de confirmar. O formulário também inclui **Esqueci minha senha** e uma tela para definir a senha após abrir o link.

O envio padrão de e-mails do Supabase é destinado a testes e tem restrições. Para disponibilizar cadastro ao público, configure um SMTP adequado no Supabase e teste confirmação e recuperação. Não prometa cadastros públicos funcionando antes desse teste.

## 5. Conferir antes de divulgar

1. Cadastre uma conta e confirme o e-mail.
2. Registre uma receita e uma despesa. Confira totais.
3. Saia e entre novamente: os dados precisam permanecer.
4. Entre em outro aparelho no mesmo endereço.
5. Cadastre uma segunda conta: ela deve começar zerada.
6. Teste metas, orçamento, recorrências, edição, exclusão, tema e assistente.
7. Teste recuperação de senha e acesso pelo celular.

O código foi verificado e a integração REST foi testada com um serviço simulado. **Seu Supabase real, as regras SQL e os e-mails ainda precisam ser verificados depois da configuração.** O pacote não está publicado na sua conta Vercel e não cria recursos externos sozinho.

## Funções e limites

Receitas, despesas, contas, parcelas, recorrência mensal por quantidade definida, calendário, orçamento, metas, ranks, exportação, configurações e assistente estão incluídos. A assistente é por regras/cálculos, sem API paga de IA e sem capacidade geral de ChatGPT.

Dados existentes no link privado do ChatGPT não são transferidos automaticamente para Supabase. São serviços de contas diferentes. Se já cadastrou dados, exporte JSON no painel antigo para manter uma cópia; este pacote não inclui importação automática.

O Google Login não está configurado nesta entrega. O cadastro usa e-mail/senha; Google pode ser conectado depois com configuração do provedor.

A sessão fica nesta aba do navegador. Fechar a aba pode exigir novo login; os dados continuam no banco. Outra aba que tenha alterado os dados gera aviso de conflito antes de sobrescrever. Rankings são conquistas simbólicas, baseadas nos registros manuais do usuário.

Planos e limites de Vercel/Supabase/SMTP podem mudar; o código não garante operação gratuita ilimitada.

## Arquivos

- `public/`: interface e integração REST.
- `supabase/configurar-banco.sql`: tabela e regras de acesso.
- `build.mjs`: prepara o site e injeta as configurações públicas.
- `vercel.json`: comandos de deploy e cabeçalhos.
- `test.mjs`: verificação de integração com serviço simulado.

Documentação: https://supabase.com/docs/guides/auth/passwords · https://supabase.com/docs/guides/database/postgres/row-level-security
