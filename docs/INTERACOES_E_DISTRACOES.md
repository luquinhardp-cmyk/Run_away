# Interações e distrações

O script comum `interactable.gd` foi estendido, sem um segundo sistema de interação. `interaction_info()` informa nome, ação, distância, chave, energia, estado e perfil sonoro. A mira usa raycast e respeita a distância do objeto. `notified(text)` continua alimentando `facility.message` e o HUD.

Objetos: porta, coleta, documento, gaveta, lata derrubável antiga, armário, bancada, painel de fusível, gerador, saída, peças metálicas, rádio e alarme. Coletas já aguardando remoção recusam nova interação. Portas recusam fechamento sobre jogador/criatura; perfis leve, metálico, pesado e enferrujado alteram o ruído. A chave da oficina só abre a fechadura `workshop` e o desbloqueio fica no save.

`scenes/interactables/throwable.tscn` usa RigidBody3D com colisão contínua, esfera simples e velocidade configurável (10 m/s + impulso vertical). Coletar seleciona a peça; MOCHILA mostra essa seleção. Mire e pressione **Q / ARREMESSAR**. Não arremessa dentro de armário, pausado, sem estoque ou encostado numa parede. O primeiro impacto audível é físico, não um temporizador: força do contato produz ruído na posição real. Cooldown de 0,45 s, até quatro impactos, limite de oito corpos e remoção em 18 s ou ao sair do mapa. Não causa dano.

Rádio toca áudio espacial original e emite estímulos a cada 1,4 s por até 35 s. Alarme dura nove segundos, é mais intenso e pode ser desligado. A criatura investiga suas fontes físicas. Nenhum deles consome bateria inventada. WAVs próprios são reproduzíveis por `tools/generate_device_audio.py`.

`WorldNoise` é Resource tipado com ID do evento/origem, posição, categoria, intensidade, duração, timestamp e perfil de propagação. `NoiseBus.noise_created` entrega o Resource; `NoiseBus.emitted` mantém dicionário compatível com consumidores antigos. Passos, corrida/agachamento, portas, peças, objetos derrubados, dispositivos, gerador, eventos e microfone usam esse barramento. Atenuação combina distância, intensidade e até três raycasts de barreiras; portas atenuam menos que concreto. Trata-se de aproximação mobile, sem simulação acústica completa.

Armários têm ID estável, posição de aproximação/câmera, ocupação, proteção e saída verificada contra colisões. Há saídas laterais alternativas para evitar aprisionamento pelo corpo da criatura. A bancada é parcialmente exposta. O microfone continua emitindo do personagem escondido.
