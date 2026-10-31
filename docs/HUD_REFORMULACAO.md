# HUD industrial

O HUD compartilhado mantém os controles existentes e recebe tema próprio em `scripts/ui/industrial_theme.gd`, ícones vetoriais originais em `assets/ui/actions`, estados pressionado/selecionado/desabilitado e rótulos contextuais. Paleta carvão, metal, verde apagado e amarelo envelhecido, com bordas discretas e texto legível.

Mochila, corrida, agachamento, lanterna, interação, arremesso, segurar/arrastar, pausa e microfone usam imagens de ação distintas. Interação muda entre porta, pegar, examinar e ativar. Corrida/agachamento/lanterna refletem o estado real do jogador; lanterna sem item e interação sem alvo ficam indisponíveis.

O medidor de ruído usa `Mic.level` real e fica zerado quando a captura está desligada. A demonstração do tutorial tem indicação SIMULAÇÃO e não altera o medidor real da captura. Não foram acrescentadas resistência, bateria ou capacidade fictícias.

Ao abrir a mochila, movimentos e toques são zerados, o mundo é pausado e o microfone suspenso. Fechar restaura a partida. Escape/Tab fecham a mochila antes de acionar pausa. Web aguarda um clique no cenário para recapturar o mouse quando necessário; arraste de toque continua usando o controlador original.

Os novos componentes não substituem IA, física ou InputMap. [Ambiente e HUD](review/tutorial-ui/preparation.png), [mochila](review/tutorial-ui/backpack.png).
