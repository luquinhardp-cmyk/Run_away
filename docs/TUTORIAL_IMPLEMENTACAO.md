# Implementação do tutorial

Arquivos principais:

- `scripts/tutorial/room.gd`: construção da sala, colisões, modelos reaproveitados, materiais compartilhados e agrupamento da geometria estática.
- `scripts/tutorial/manager.gd`: critérios, progresso, recuperação da lata, demonstração e transição.
- `scripts/tutorial/lesson.gd`: textos, controles e dicas das nove etapas.
- `scripts/tutorial/interaction.gd`: extensão do interactable existente para console, quadro e confirmação da saída.
- `scripts/tutorial/hud.gd`: extensão do HUD compartilhado; usa a mesma mochila visual.
- `scenes/tutorial/{preparation,hud}.tscn`: pontos de entrada.

O jogador, inventário, porta articulada, esconderijo, painel de fusível, lanterna e projétil são os originais. Os sinais `Game.updated`, `NoiseBus.emitted`, `inventory_viewed` e `player.tutorial_action` controlam ações. Um Timer de 10 Hz amostra mira, silêncio, permanência no armário e posição da passagem. Não existe uma segunda IA ou controlador de movimento.

O mapa principal não é instanciado durante o tutorial. A exportação Web ainda baixa o pacote inicial completo da engine/projeto; isto não é streaming de download por mapa. Modelos da criatura e a floresta são instanciados apenas na fase principal.

O exercício revelou que CCD podia reduzir a velocidade um tick antes de disponibilizar o contato. `physical_prop.gd` conserva uma amostra anterior adicional para reconhecer o impacto real, sem fabricar eventos. O teste também verifica que a lata parada não continua emitindo ruído.

Para evitar liberar um objeto ainda emitindo sinal, a transição para a fase é conectada com `CONNECT_DEFERRED`. O teste confirma que a preparação foi efetivamente destruída, incluindo suas colisões.
