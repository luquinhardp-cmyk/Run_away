# Áudio de impactos

Componente `PhysicsImpactAudio` em `scripts/physics/impact_audio.gd`. Recebe material do corpo/superfície, ponto real de contato, velocidade relativa e massa. `_integrate_forces` lê contatos do solver; não adivinha impacto pela posição do jogador. Materiais físicos vêm de PhysicsSurfaces.

Limiar padrão: 0,8 m/s; intervalo mínimo: 0,32 s. Intensidade depende de velocidade, raiz da massa e absorção da superfície; raio de 5–35,8 m. Metal, madeira, vidro, borracha e peso selecionam timbre, com três samples cada. Som e NoiseBus são emitidos uma única vez pela mesma decisão. Entre dois corpos que usam o componente, o menor instance_id é dono do evento, evitando duplicação dos dois lados do contato. Contato parado não dispara som a cada quadro.

`tools/art/generate_impact_audio.py` cria 21 WAVs originais PCM16 mono 22.050 Hz: metal, wood, glass, rubber, heavy, chain e slide, três variações por banco. Manifesto registra duração, pico e origem. São sínteses para gameplay, não gravações de estúdio nem simulação acústica de cada combinação de superfícies. Superfície influencia absorção, enquanto material e massa do objeto definem o banco principal.

`Sound.physics_impact` compartilha cache, evita repetição imediata de sample, varia pitch e limita vozes junto aos demais efeitos. A corrente suprime o ruído inicial próprio quando um objeto a atinge: o objeto relata a colisão e o balanço pode produzir um tilintar posterior. Portas, gaveta e máquinas mantêm eventos de mecanismo separados dos impactos.

Eventos chegam à IA pela posição do contato. Teste confirmou estado ALERT e last_known no ponto do objeto, distante do jogador. Ocultação/atenuação por paredes e portas continua a cargo de NoiseBus. Ganho e output_guard respeitam configurações; ainda é necessário calibrar microfone/alto-falante no telefone. Não há cancelamento de eco acústico.
