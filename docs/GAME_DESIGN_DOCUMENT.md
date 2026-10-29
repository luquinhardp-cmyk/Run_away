# ECOS / documento de design

## Pilar
Sobreviver por silêncio e posicionamento. A criatura Ouvinte é invulnerável. O jogador anda a 2,45 m/s, corre a 4 m/s e agacha a 1,25 m/s. A criatura patrulha a 1,55 m/s e persegue a 3,35 m/s; a corrida permite criar distância, mas produz ruído.

## Planta e progressão

Cada célula mede 4 m; corredor de 44 m, largura 4 m; salas laterais de 8 × 4 m. Coordenadas Godot, Y vertical, avanço em -Z.

```text
Enfermaria [-8..-2] ── z=  0  início / lanterna / anotação / armário
                         │
                         ├── z= -8  manutenção [2..10] / fusível / gaveta / armário
Depósito [-10..-2] ───── z=-16  distração metálica / armário
                         │
                         ├── z=-24  segurança [2..10] / cartão / porta elétrica
Energia [-10..-2] ────── z=-32  gerador / armário / checkpoint
                         │
                         └── z=-40  corredor de fuga / saída
```

A saída exige energia e cartão. O gerador exige fusível e gera um ruído alto. A porta da segurança só abre para o jogador com energia. Obter o cartão atrai a criatura à segurança, criando pressão na fuga final sem teletransporte. Um impacto no depósito é acionado uma única vez quando o jogador avança pelo corredor. A criatura tem oito segundos iniciais sem percepção ativa.

## Vulnerabilidade
O armário interrompe movimento e visão da criatura, mas mantém ruídos do microfone. Ruído forte ouvido enquanto escondido permite investigação e ataque próximo. A lanterna amplia o alcance visual da criatura. Agachar e apagá-la reduzem detecção. Perder linha de visão leva a busca na última posição, sem rastreamento constante do jogador.

## Atmosfera e acessibilidade
Paleta verde oxidado, luz quente nas salas, paredes com ruído procedural, vigas, tubulações, papéis, mobiliário, áudio espacial e névoa discreta. Sem flashes ou sustos aleatórios recorrentes. Volume geral/efeitos/música, FOV, sensibilidade e intensidade dos sustos ajustáveis. Feedback de perseguição é uma camada vermelha de baixa opacidade. Sons têm amplitude limitada na fonte.

## Progresso
Checkpoint ao restaurar energia: retoma sempre na enfermaria com inventário e mecanismos preservados. Vitória e derrota têm reinício e retorno ao menu. Uma nova sessão não elimina o último checkpoint até atingir um novo. Itens não são consumidos nesta versão, evitando softlocks.

## Expansão
Substituir o placeholder da criatura por rig, materiais e animações; adicionar mais eventos roteirizados e variações de ambiente. Antes de expandir a fase, medir legibilidade, tempo de fuga e taxa de captura em aparelhos reais.
