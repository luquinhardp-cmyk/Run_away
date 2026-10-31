# Evento de voo

`scripts/environment/flying_shadow_event.gd` instancia FlyingShadowEvent sob BloodMoonNight. Configuração tipada em `flying_config.gd` e `resources/environment/flying_config.tres`; padrões em `resources/environment/flights/*.tres`.

Sete padrões: cruzar lua, distante, próximo, subida das copas, voo com asas sem grito, lua completamente silenciosa e grito após desaparecimento. Seleção ponderada sem repetição consecutiva, com estado de último padrão mantido durante a execução. Trajetórias Bézier são congeladas no espaço ao iniciar; não seguem a câmera do jogador. Os dois padrões lunares usam a direção fixa da lua. Velocidade varia pela distância/traçado; duração limitada a 24 segundos.

Cooldown inicial e entre eventos sorteado em 240–540 segundos. Depois, a cada oito segundos elegíveis, chance de 22%; 540 segundos não garantem um evento. Exploração mínima 35 segundos. Direção vertical real da câmera exige componente y>=0.22; raycast frontal verifica céu livre. Região externa é o pátio jogável e exige raycast vertical sem teto. Não basta altura da câmera. Sem olhar para cima, uma chance muito menor permite somente o grito fora de vista.

Captura, pausa, perseguição/ataque terrestre, tensão alta, perseguição recente, susto recente e reserva ativa do HorrorDirector bloqueiam início. O evento reserva `active_until` e redefine `since_scare`; sua própria reserva não o cancela. Captura, perseguição ou entrada em prédio durante voo encerram a aparição. Pausa congela trajetória. Só uma entidade fica ativa. Não emite NoiseBus para fabricar percepção terrestre.

Sinais `appeared(id)` e `vanished(id)` permitem futura integração narrativa. O estado de evento aéreo não foi adicionado ao checkpoint: carregar inicia novo cooldown de pelo menos quatro minutos. A história de padrões não persiste após fechar o aplicativo. Isso não altera o schema de salvamento existente.

`tests/night_runner.tscn`: 76 verificações aprovadas, incluindo teto físico no pátio, direção horizontal rejeitada, sete trajetórias contínuas, lua, pausa, áudio silencioso, grito atrasado, cooldown e não repetição. Nenhum modo de testes acelera eventos na versão distribuída.
