# ECOS 0.11.0

Publicação autorizada pelo usuário em 01/11/2026. Inclui o gerador industrial real no tutorial, acionamento e salvamento da energia, porta dependente de energia, correções do piso externo junto à entrada, recuperação de quedas com diagnóstico local, controles Web de tela/rotação e microfone, carregamento por etapas e ajustes de custo gráfico.

Endereços permanentes preservados:

- https://run-away-ecos.pages.dev/
- https://run-away-ecos.pages.dev/play/
- https://run-away-ecos.pages.dev/baixar-apk

Android: pacote `org.ecos.instalacaoabandonada`, versão 0.11.0, versionCode 11. Mantida a assinatura de depuração das versões de teste anteriores, para permitir atualização sobre a instalação existente. A verificação contra o APK 0.10.0 consta em `review/tutorial-generator/android-update-011.json`. Não é assinatura para distribuição em loja; não foi realizada instalação física.

Validação anterior à publicação: 260 verificações nativas da integração final e 53 verificações do tutorial no Chromium/WebGL. Regressões de estabilidade e recursos Web estão detalhadas em `TESTES_REGRESSAO.md`; os totais históricos não devem ser somados como testes únicos da versão final. O encerramento automatizado da engine Web registra avisos de duas texturas GL e WorkerThreadPool; o percurso do tutorial teve zero erros durante execução.

Relatórios: `TUTORIAL_GERADOR_CORRECAO.md`, `CORRECAO_QUEDA_MAPA.md`, `WEB_FULLSCREEN_LANDSCAPE.md`, `MICROFONE_CONTROLE_HUD.md`, `WEB_OTIMIZACAO.md` e `TESTES_REGRESSAO.md`. As indicações de entrega local/não publicada nesses documentos registram a etapa anterior à autorização atual.

Limites: desempenho, microfone real e instalação em Android/iPhone físicos continuam pendentes. Há engasgos de compilação de shaders documentados. A configuração iOS não equivale a IPA assinado ou TestFlight. O Firebase continua responsável por contas e progresso; esta publicação não modifica suas regras ou dados. Somente o site final da cena principal deve ser publicado; os pacotes com suítes de QA não devem ser enviados ao Cloudflare.
