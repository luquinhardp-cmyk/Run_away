# Regressão de estabilidade, entrada e microfone

Resultados consolidados e logs: [validation.json](review/stability/validation.json). Os relatórios registram contagens efetivas; arquivos de tentativas diagnósticas anteriores não são apresentados como aprovação.

Resultado: 800 verificações nativas aprovadas em 15 suítes, 47 verificações de estabilidade no Web e 14 verificações do wrapper em Chromium. Os smokes da fase real com toque emulado e com mouse/teclado concluíram sem erros, incluindo microfone sintético, mochila, IndexedDB e recarga. O teste desktop confirmou pointer lock por clique e liberação pela mochila; o jogo não tenta capturá-lo automaticamente após o carregamento assíncrono.

O QA Web induz intencionalmente a ausência de destino seguro e conserva seu aviso de fallback. Há também um aviso WorkerThreadPool ao encerrar a engine do teste. Mensagens brutas, avisos esperados e erros inesperados ficam separados em `qa/chromium-qa.json`; os erros inesperados durante o percurso são zero. As primeiras tentativas da automação que não atravessavam a nova tela de entrada ficam registradas como falhas do fixture, sem contá-las como aprovação.

Entrega local: `builds/stability/ecos-web-stability.zip` e `builds/stability/ecos-android-diagnostic.apk`. Manifesto e hashes: `review/stability/artifact.json`.

- `stability_runner`: chão dos ombros, movimento real em ambos os sentidos nas três velocidades, cercas, corpo rígido, recuperação, fallback, cápsula livre, câmera/velocidade, persistência local, rampa/subsolo, proteção contra repetição e manutenção de inventário/sons do mundo.
- `staged_start_runner`: frames intermediários, construção concluída antes de jogadores/IA, navegação pronta e tempo de fuga sem carregamento. O fixture aguarda o desempilhamento do sinal antes de liberar a cena.
- `map_safety_audit`: 42 sondagens na entrada, 158 nas demais rotas e 253 colisores estruturais. Não substitui exploração manual contínua de toda a superfície.
- Regressão: runner, expansion, physics, horror, received_creature, macabre, graphics, geometry, night, inventory, tutorial, tutorial_persistence e web_audit.
- Browser: wrapper/fullscreen/orientação e dispositivo sintético; fase real com botão de microfone, mochila, IndexedDB e rotação. Os testes de física Web usam um fixture que neutraliza a pausa acidental de foco da automação; o comportamento de visibilidade é testado separadamente.

Exportação local Web e APK Android de diagnóstico, mantendo package ID, certificado e versão de produção 0.10.0. Este APK não é uma nova versão pública numerada. O link canônico continua apontando para o APK já publicado até nova autorização.

Não houve push, release ou deployment nesta etapa. O artefato Web local é marcado como não publicado. Os dados Firebase e as assinaturas existentes não foram alterados. iOS permanece com os presets existentes, sem compilação/assinatura em Mac, Safari físico, aparelhos Android/iOS ou microfone físico testados.

Limites explícitos: medições curtas e uma repetição por configuração; picos de compilação/carregamento continuam registrados em WEB_OTIMIZACAO.md. A ausência de erro durante o smoke não garante desempenho em todos os aparelhos. Avisos de teardown da engine, se presentes, ficam no log bruto, separados dos erros durante o percurso.
