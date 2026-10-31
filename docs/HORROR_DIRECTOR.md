# Diretor de tensão

`scripts/horror/horror_director.gd` observa a criatura real e administra tensão 0–5: calma, atenção, proximidade, investigação próxima, perseguição e captura. Ruído forte do microfone pode elevar atenção, sem agendar susto por si só. Depois de perseguição existe intervalo de alívio de 14 segundos; eventos são bloqueados durante captura, perseguição, proximidade perigosa, pausa e cooldown.

Nove Resources em `resources/horror/events` definem id, categoria, área, intensidade, peso, condições de energia, alcance, intervalo, máximo e persistência. Biblioteca: batida, abertura lenta, fechamento, queda suave de luz, falha breve da lanterna, deslocamento de objeto, rádio, presença verdadeira e arrasto da criatura. Intensidade limita seleção conforme tensão. Luz varia em curva suave; opção de acessibilidade elimina falhas de iluminação.

Escolha ponderada reduz peso dos dois eventos recentes. Intervalo global de 22–38 segundos aumenta com intensidade de sustos reduzida. Máximos e cooldowns individuais evitam spam. Portas trancadas não abrem; ocupantes bloqueiam fechamento. Presença verifica linha de visão ao NPC real; não instancia cópias ou muda sua posição. Objetivos, rotas e colisões existentes são preservados.

Seed inicia RNG separado. Checkpoint contém `world.horror`: counts dos eventos persistentes, seis entradas de history, cooldown_remaining e rng_state como string (preserva inteiro de 64 bits no JSON). Checkpoints antigos sem horror continuam válidos. Regras Firestore aceitam o campo opcional e mantêm isolamento por proprietário. O relógio de cooldown individual não atravessa carregamento, mas contagens máximas e intervalo global sim; esse limite evita armazenar relógios absolutos inválidos.

A vinheta é leve, sem bloquear input, controlada por acessibilidade. Não há sombras dinâmicas extras no perfil baixo. O sistema fornece base configurável; novos mapas precisam validar fontes físicas e áreas.
