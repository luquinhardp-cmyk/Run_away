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
