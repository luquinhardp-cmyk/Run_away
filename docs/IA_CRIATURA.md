# Ouvinte / IA

## Estados
Patrulha visita quatro pontos; ociosa espera 2,5 s; alerta vira ao estímulo por 1,6 s; investigação aproxima a última posição ou expira em 14 s; busca verifica proximidade e procura ao redor por 6,5 s; perseguição corre a 3,35 m/s; perda de alvo segue a última posição; retorno volta à patrulha; ataque tem antecipação de 0,65 s e derrota. A versão 0.2 usa GLB com skinning e 29 ossos. O estado alerta aciona a animação listen, com cabeça inclinada e conchas articuladas. Detalhes em CRIATURA_PRINCIPAL.md.

## Audição
Intensidade × (1 - distância/raio)^1,4. Até três barreiras por raycast: portas multiplicam intensidade por 0,55; paredes por 0,25. É um modelo barato, não simulação acústica: uma parede representada por vários corpos pode atenuar mais. Eventos somam suspeita, que decai; ruído suficiente altera estado e atualiza última posição. Sem estímulo, a criatura não recebe posição atual do jogador fora da percepção visual. Ruído intenso no armário marca possibilidade de descoberta durante busca próxima.

## Visão
Cone de 110°, raycast para a câmera, alcance de 15 m com lanterna, 9 m em pé sem lanterna e 5,5 m agachado. É aproximação de exposição por estado, não leitura física da iluminação. Visão ignora jogador escondido. Após ~2,4 s sem visão, perseguição passa à perda de alvo e busca. Paredes e portas fechadas bloqueiam a visão.

## Navegação
NavigationRegion3D e NavigationAgent3D com navmesh baked a partir das colisões do nível. O corpo usa move_and_slide e não se teletransporta. Portas dinâmicas ficam fora do bake: se bloqueiam a criatura, ela abre a porta ao detectar que não progrediu. Após cinco segundos travada, troca ponto de patrulha e tenta retorno. Casos complexos de congestionamento ainda precisam de playtest.

## Balanceamento
Primeiros oito segundos seguros para orientar o jogador. Jogador corre mais rápido que a criatura, mas chama atenção a até 18 m. O gerador emite até 36 m e pode ser ouvido durante a fuga até a segurança. Obter o cartão manda investigar a sala do cartão; não move instantaneamente a criatura.
