# ECOS 0.10.0

Atualização autorizada pelo usuário para GitHub e Cloudflare. Inclui tutorial 3D, mochila visual e inspeção, HUD, correções da auditoria Web, preparação iOS e a substituição da criatura pelo Escutador_Monstro_3D.glb com rig e animações.

Endereços permanentes:

- https://run-away-ecos.pages.dev/
- https://run-away-ecos.pages.dev/play/
- https://run-away-ecos.pages.dev/baixar-apk

Android: pacote `org.ecos.instalacaoabandonada`, versionCode 10, versão 0.10.0. APK ARM64 de testes assinado com o certificado de depuração já utilizado nas versões anteriores. A comparação de identidade e assinatura está em `review/escutador_macabre/android-update-010.json`. A assinatura de distribuição para loja não faz parte desta entrega.

Validação: 328 verificações nativas da integração final e 29 verificações de terror/capturas no Chromium. As etapas anteriores de tutorial/UI tiveram 693 verificações aprovadas antes da substituição do modelo. Não somar esses totais como verificações únicas da versão final. Os testes Web passaram sem erro durante o percurso, mas o encerramento automatizado da engine registra um aviso WorkerThreadPool, preservado no relatório.

Relatórios detalhados: `ESCUTADOR_MACABRO_INTEGRACAO.md`, `TUTORIAL_UI_ENTREGA.md` e `WEB_AUDITORIA_TECNICA.md`. As menções a entrega local/não publicada nesses documentos registram o estado anterior a esta autorização.

Limites: Android/iPhone físicos, microfone real e desempenho térmico continuam pendentes. A configuração iOS não equivale a um IPA assinado ou uma publicação TestFlight. O novo monstro é baseado no GLB fornecido e não possui o detalhamento fotográfico da imagem de referência. Firebase permanece responsável pelas contas e progresso; esta publicação não altera regras ou dados existentes.

## Publicação concluída em 31/10/2026

Código enviado às branches `feature/ios-support` e `feature/base-survival-horror-3d`. Build publicado: commit `8a81001a998c9a466bd8a41610ee0c2e36000598`. Release de testes no GitHub: `v0.10.0-tutorial-macabre`, com APK de 55.298.395 bytes. Deployment Cloudflare de produção: `95264aa4`.

Verificação dos endereços permanentes: raiz e `/play/` com HTTP 200; `/version.json` confirma 0.10.0 e o commit acima; `/baixar-apk` retorna 302 para o APK 0.10.0, cujo download público responde 200 e tem o tamanho esperado. MIME e gzip do WASM conferidos. O smoke no Chromium acessou o domínio público, abriu e fechou a mochila, salvou o tutorial no IndexedDB e recuperou a preparação após recarregar, sem erros de console.

Evidências: `review/escutador_macabre/production-010-verification.json` e `review/escutador_macabre/production-010-browser.json`.
