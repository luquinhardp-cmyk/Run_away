# Publicação de testes

Solicitada pelo usuário após a implementação. Repositório: [luquinhardp-cmyk/Run_away](https://github.com/luquinhardp-cmyk/Run_away), branch `feature/base-survival-horror-3d`. Nenhum push, deploy ou alteração no Desolação RPG.

## Build

```powershell
godot --headless --path . --export-release Web builds/web/play/index.html
python hosting/prepare.py
godot --headless --path . --export-debug Android builds/ecos-android.apk
```

Requer export templates Godot 4.7.2 da plataforma. `builds/` é ignorado no Git. Os fontes da página de entrada e das regras de hosting ficam em `hosting/`; configs Firebase em `firebase.json` e `.firebaserc`. O APK é anexado à pré-release `v0.1.0-test` no GitHub; o link da página aponta para esse asset. A assinatura é debug, destinada a testes.

`prepare.py` comprime `index.wasm` com gzip e mantém a extensão. Isso deixa o arquivo abaixo do limite de 25 MiB por arquivo do Cloudflare Pages. **É obrigatório servir com Content-Encoding: gzip e Content-Type: application/wasm**: as regras `_headers` e Firebase já fazem isso. Não servir este pacote com `python -m http.server` puro depois da compressão; esse servidor não adiciona Content-Encoding.

## Cloudflare

Projeto dedicado `run-away-ecos`, conta pessoal do usuário. Produção configurada para a branch `feature/base-survival-horror-3d`.

```powershell
npx wrangler pages deploy builds/web --project-name run-away-ecos --branch feature/base-survival-horror-3d
```

URL de produção: `https://run-away-ecos.pages.dev/`. A página de entrada oferece jogo em `/play/` e download do APK no GitHub Releases. Nenhum domínio personalizado foi alterado.

## Firebase

Projeto explicitamente indicado: `run-away-f63e4`. Apenas Hosting, sem banco, regras ou Functions.

```powershell
firebase login --reauth
firebase deploy --only hosting --project run-away-f63e4
```

O primeiro acesso disponível nesta sessão retornou 401 por credencial expirada. A reautenticação foi iniciada para o usuário concluir no navegador. A existência desta configuração não significa que o deploy Firebase tenha sido concluído; verificar o resultado da CLI antes de divulgar a URL como ativa.

## Testes e limites Web

Chromium desktop headless carregou menu, consentimento e fase 3D sem erros JavaScript/GDScript. A captura Web usa áudio Stream porque efeitos não funcionam no modo Sample. Navegadores e SOs controlam permissão e indicadores de microfone. Entrada física de áudio, iOS/Safari e dispositivos móveis não foram validados. O jogo continua utilizável sem microfone.

Fonte: [Godot: exportar para Web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).
