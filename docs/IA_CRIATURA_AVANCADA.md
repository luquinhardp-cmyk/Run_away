# IA da criatura

O controlador e a apresentação existentes foram estendidos. `creature.gd` mantém os índices dos nove estados para preservar os clipes do GLB. `CreatureProfile` (`resources/ai/easy|normal|hard.tres`) configura velocidades, reação, FOV, alcance, audição, persistência, aviso de armário e recursos. Não existe stun: não foi introduzido combate.

| Estado | Entrada, comportamento e saída |
|---|---|
| PATROL | Percorre pontos configuráveis por NavigationAgent3D; chega e entra IDLE |
| IDLE | Respira parado por 2,5 s; retoma patrulha ou reage a evidência |
| ALERT (SUSPICIOUS) | Ruído audível; para e inclina a cabeça por 1,6 s; investiga a origem |
| INVESTIGATE | Segue pista sonora, com timeout de 14 s; inicia busca ao chegar |
| SEARCH | Gera até dez pontos acessíveis, próximos primeiro, e visita locais ainda não examinados; pode examinar armários com pistas; expira conforme dificuldade |
| CHASE | Evidência visual acumulada supera limiar; acompanha última observação e previsão limitada a 0,6 m; perde contato após tolerância |
| LOST (LOST_TARGET) | Avança à última posição vista por até 2 s; inicia SEARCH |
| RETURN | Retorna ao ponto de patrulha, com timeout de 12 s |
| ATTACK | Exige visão e alcance, ou ocupação confirmada num armário investigado; captura após 0,65 s; cancela se as condições deixarem de existir |

Velocidades normais: patrulha 1,55, investigação 1,9 e perseguição 3,35 m/s. Jogador corre a 4 m/s. Fácil oferece reação e busca menores, aviso maior e sete objetos; difícil aumenta persistência/sensores e reduz objetos para três, sem depender apenas de velocidade.

`CreaturePerception` avalia FOV horizontal, alcance, postura, movimento e raycast mundo/jogador. Atualiza a cada 0,18 s. Paredes e portas fechadas bloqueiam. Lanterna e postura são pistas explícitas de exposição; **não há medição de luminosidade do renderer**. O armário oferece proteção total contra visão direta; a bancada oferece proteção parcial. Isso não impede investigação local nem captura confirmada.

`CreatureMemory` separa posição visual e sonora, direção observada, idade/força/origem do som, pistas de armários, 16 locais e 16 resultados recentes. Som não sobrescreve memória visual numa perseguição. Fontes fracas não substituem imediatamente uma pista forte recente. Repetição da mesma fonte atualiza destino sem reiniciar continuamente a pose de escuta. Suspeita e pistas decaem.

`CreatureSearch` usa marcadores do cenário, anéis crescentes, projeção e caminhos reais. Descarta pontos inacessíveis ou repetidos. Armários só ganham suspeita por entrada testemunhada com LOS, som de entrada ou microfone próximo. O inimigo não consulta a posição oculta para escolher armário; só consulta ocupação após chegar e avisar por 1,8–3 s. O jogador pode sair durante o aviso.

Portas operáveis são abertas após bloqueio físico. Após cinco segundos sem progresso, a criatura abandona aquela rota e retorna à rotina; não teletransporta. `state_changed(previous, current)` permite diagnóstico e extensão. A apresentação continua em `escutador_visual.gd`.
