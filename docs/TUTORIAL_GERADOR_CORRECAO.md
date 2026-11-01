# Correção do gerador do tutorial

## Causa e cena

O gerador não era instanciado em `scripts/tutorial/room.gd`. A etapa 8/9 terminava ao ler a missão, consultar objetivos e instalar o fusível; o texto do painel mandava acionar um gerador inexistente. A preparação usa `scenes/tutorial/preparation.tscn`, construída pelo gerenciador `scripts/tutorial/manager.gd`.

## Implementação

- Gerador industrial existente `assets/models/library/diesel_generator.glb`, com variante `_low`, materiais compartilhados, motor, painel, tubulações e estrutura. Nenhum modelo duplicado. Instanciado em `(3.5, 1, -29.5)`, apoiado no piso, à direita do quadro; painel de fusível fica à esquerda.
- Colisor de caixa 1,3 × 2 × 0,8 m, camadas de mundo/interação 1 e 8. Mantida a detecção real por mira, E e botão INTERAGIR do HUD.
- Placa, luz de manutenção sem sombras e conduíte ligando visualmente painel, motor e porta. Placas da missão e entrada foram reduzidas para caber na geometria.
- A lição agora orienta `fusível → painel → gerador`. As demais lições, leitura da missão e consulta de objetivos continuam obrigatórias. A dica reaparece após 25 segundos de inatividade.
- A interação reaproveita as verificações do gerador principal, sem modificar sua IA ou o comportamento do gerador da fase. Exige estar na lição correta e ter instalado o fusível.
- Partida reproduz o áudio existente `assets/audio/generator.wav`; o mesmo recurso é reutilizado em um emissor 3D local com repetição, atenuação e volume de -26 dB. Há movimento do interruptor e vibração visual de 2 mm; o colisor permanece estável.
- Energia atualiza o indicador do gerador, a luz da antecâmara, o indicador vermelho/verde da porta e recolhe a pequena trava visual. A porta permanece fisicamente fechada até confirmação explícita; sua dobradiça e a passagem sem retorno originais foram preservadas.
- Ausência, invisibilidade do nó, deslocamento, erro de tipo/ação/gerenciador, falta de modelo ou colisor/camada inválidos produzem diagnóstico de desenvolvimento e impedem a saída. Não há desbloqueio automático para contornar falhas.

## Estado e salvamento

`generator_powered` é persistido no progresso de preparação, versão 2, junto ao fusível, etapa, inventário e ações já concluídas. Em execução, é sincronizado com `Game.power` e `Game.world.generator_started`. A porta exige esses estados e a validação do gerador. O motor e os indicadores são restaurados sem repetir o som de partida nem abrir automaticamente a porta.

`Game.tutorial_progress()` aceita versões 1 e 2. Saves antigos na etapa final, sem gerador acionado, retornam à etapa de energia, preservando as ações anteriores. O jogador precisa ligar o gerador de verdade. A travessia continua registrando `stage: entered` antes do fechamento, impedindo retorno após sair/reabrir durante a transição. Ao entrar no complexo, a energia e os itens de treino são descartados, preservando a progressão real da fase.

## Arquivos desta correção

`scripts/tutorial/{room,manager,interaction,lesson}.gd`, leitura de versão em `scripts/systems/game.gd`, `tests/tutorial_runner.gd`, `tests/tutorial_persistence.gd`, `tests/tutorial_generator_review.{gd,tscn}` e este relatório. Existem outras alterações locais anteriores de estabilidade; elas foram preservadas e não fazem parte desta correção.

## Verificação

260 verificações nativas passaram, sem falhas: tutorial 53, persistência 16, inventário 23, base 80, expansão 41 e estabilidade 47. Evidência: `docs/review/tutorial-generator/native-results.json` e logs de cada suíte. A sequência usa o raycast real de interação e o jogador real, incluindo caminhada física entre painel, gerador e porta, recusa sem fusível, recusa da porta sem energia, ativação, áudio, modelo, indicadores, trava, confirmação, cancelamento, travessia, descarregamento da preparação e ausência de vazamento de itens/energia para a fase.

Persistência foi exercitada em JSON antes e depois da partida, com motor restaurado, entrada ainda fechada, migração de save antigo e bloqueio de retorno. Renderização real OpenGL Compatibility na Intel UHD foi inspecionada nas capturas `docs/review/tutorial-generator/01-generator-off.png`, `02-generator-running.png` e `03-powered-airlock.png`.

No Chromium real com WebGL e emulação de tela touch, a mesma sequência executou **53 verificações, sem falhas**, incluindo a interação pelo jogador, caminhada e transição para a fase. O relatório final está em `docs/review/tutorial-generator/web/chromium-qa.json`. O teste usa a interface real do exportador e o wrapper de navegador do projeto; não representa teste em aparelho físico. A primeira tentativa local foi reexportada sem reaplicar `hosting/prepare.py`, portanto ficou sem `EcosWeb` e gerou erros de integração; o pacote foi preparado corretamente e o teste repetido. A evidência inicial foi preservada na subpasta `initial-export-without-wrapper`.

O exportado `builds/tutorial-generator-qa/site` é **exclusivo de QA**, com a suíte automatizada como cena inicial; não é versão pública nem pacote para distribuição. `source-manifest.json` confirma que os sete arquivos de lógica/teste usados no pacote correspondem às fontes locais.

O navegador registrou zero erros durante a execução. Ao encerrar o motor da suíte, registrou dois avisos de textura GL não liberada (5.460 bytes cada) e um aviso do alocador de WorkerThreadPool. Permanecem registrados em `shutdownErrors`; não foram corrigidos nem tratados como erros de gameplay nesta entrega.

## Limites e publicação

Android físico, iPhone/iPad, Safari e microfone físico não foram testados nesta correção. Volume perceptivo e desempenho nesses aparelhos ainda exigem teste real; não são garantidos por execução no PC. Foram reutilizados recursos compatíveis e controles existentes, sem alterar exportações ou identificadores dos aplicativos.

Nenhuma publicação no Git remoto, Cloudflare ou Firebase foi realizada. A versão pública permanece inalterada, conforme a instrução deste pedido.
