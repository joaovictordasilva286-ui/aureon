import fs from 'node:fs';
const url=process.env.SUPABASE_URL||'',key=process.env.SUPABASE_PUBLISHABLE_KEY||'';
if(!url||!key)throw Error('Configure SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY na Vercel antes de publicar.');
const parsed=new URL(url);if(parsed.protocol!=='https:')throw Error('Use a URL HTTPS do Supabase.');
if(key.startsWith('sb_secret_'))throw Error('Use a chave PUBLICÁVEL, nunca uma chave secreta.');
if(key.startsWith('eyJ')){try{if(JSON.parse(Buffer.from(key.split('.')[1],'base64url')).role!=='anon')throw Error('Use anon, não service_role.')}catch{throw Error('A chave precisa ser publicável ou anon.')}}
fs.mkdirSync('dist',{recursive:true});fs.cpSync('public','dist',{recursive:true});
fs.writeFileSync('dist/config.js','window.AUREON_CONFIG='+JSON.stringify({url:parsed.origin,key})+';');
console.log('Aureon preparado para Vercel.');
