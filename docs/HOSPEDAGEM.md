# Publicação de testes

Solicitada pelo usuário após a implementação. Repositório: [luquinhardp-cmyk/Run_away](https://github.com/luquinhardp-cmyk/Run_away), branch `feature/base-survival-horror-3d`. Nenhum push, deploy ou alteração no Desolação RPG.

## Build

```powershell
godot --headless --path . --export-release Web builds/web/play/index.html
python hosting/prepare.py
godot --headless --path . --export-debug Android builds/ecos-android.apk
```

Requer export templates Godot 4.7.2 da plataforma. `builds/` é ignorado no Git. Os fontes da página de entrada e das regras de hosting ficam em `hosting/`; configs Firebase em `firebase.json` e `.firebaserc`. O APK é anexado à pré-release `v0.2.0-art` no GitHub; o link da página aponta para esse asset. A assinatura é debug, destinada a testes.

`prepare.py` comprime `index.wasm` com gzip e mantém a extensão. Isso deixa o arquivo abaixo do limite de 25 MiB por arquivo do Cloudflare Pages. **É obrigatório servir com Content-Encoding: gzip e Content-Type: application/wasm**: as regras `_headers` e Firebase já fazem isso. Não servir este pacote com `python -m http.server` puro depois da compressão; esse servidor não adiciona Content-Encoding.

## Cloudflare

Projeto dedicado `run-away-ecos`, conta pessoal do usuário. Produção configurada para a branch `feature/base-survival-horror-3d`.

```powershell
npx wrangler pages deploy builds/web --project-name run-away-ecos --branch feature/base-survival-horror-3d
```

URL de produção: `https://run-away-ecos.pages.dev/`. A página de entrada oferece jogo em `/play/` e download do APK no GitHub Releases. Nenhum domínio personalizado foi alterado.

## Firebase

Projeto explicitamente indicado: `run-away-f63e4`. A partir de 0.3, Firebase fornece Authentication (e-mail/senha) e Firestore em São Paulo. Cloudflare serve o jogo.

```powershell
firebase deploy --only firestore:rules --project run-away-f63e4
```

O endereço legado **https://run-away-f63e4.web.app/** somente redireciona ao **https://run-away-ecos.pages.dev/**. `firebase.json` conserva esse redirecionamento sem hospedar outra cópia do jogo. As regras restringem dados ao dono autenticado; veja `CONTAS_E_PROGRESSO.md`. O APK está na release `v0.3.0-cloud` (versionCode 3).

O teste após a primeira publicação detectou que as CDNs entregavam bytes gzip residuais ao compilador WebAssembly. `wasm-loader.js` normaliza a resposta exclusiva de `index.wasm`: verifica a assinatura e descomprime os bytes residuais com DecompressionStream, preservando respostas já descomprimidas. O preparo injeta esse carregador antes do código da engine. Essa versão requer navegador com DecompressionStream (ou a resposta deve já chegar descomprimida).

## Testes e limites Web

Chromium desktop headless carregou menu, consentimento e fase 3D sem erros JavaScript/GDScript. A captura Web usa áudio Stream porque efeitos não funcionam no modo Sample. Navegadores e SOs controlam permissão e indicadores de microfone. Entrada física de áudio, iOS/Safari e dispositivos móveis não foram validados. O jogo continua utilizável sem microfone.

Na URL publicada do Cloudflare, o teste de ciclo de vida com dispositivo sintético do Chromium observou: **0 chamadas getUserMedia antes do consentimento; 1 chamada e faixa live depois de permitir; a mesma faixa ended ao pausar com Esc**. Isso valida o fluxo do navegador com dispositivo de teste, sem validar hardware acústico. Os dois hosts carregaram a engine após a correção WASM. Capturas remotas simultâneas em renderização por software sofreram timeout; a verificação de microfone foi repetida isoladamente e passou. A suíte Godot permaneceu com 43 verificações passando, 0 falhas.

Fonte: [Godot: exportar para Web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).

## Revisão de arte 0.2

A mesma autorização de publicação para testes cobre esta atualização. O APK novo usa versionCode 2 e versionName 0.2.0; a release 0.1 anterior permanece disponível. Mapas PBR e GLBs estão no pacote; fontes Blender e ferramentas de autoria ficam no repositório, excluídos do build. O relatório de arte e os 69 testes estão em `OTIMIZACAO_GRAFICA_ANDROID.md`.
