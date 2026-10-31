# Renderização

`scripts/systems/graphics.gd` aplica resolução, MSAA, limite de FPS e atlas de sombras. Não usa TAA nem efeitos volumétricos. Perfis: baixo 30 FPS/80%/sem sombras da lanterna; médio alvo até 60 FPS/100%/lanterna; alto alvo até 60 FPS/100%/lanterna e lua. Alvos não são garantias de desempenho. Sombras podem ser alteradas independentemente.

Luzes locais são atenuadas/desativadas por distância; a lua usa uma projeção de sombras ortogonal no alto. Os contadores anteriores não demonstraram redução de draw calls pelo desligamento de luzes: não se reivindica essa redução. A geometria nova e as sombras aumentam o custo em algumas vistas.

Texturas passaram a gerar mipmaps, com compressão lossless mantida. A memória de textura registrada cresceu: consultar os JSON do comparativo. Não foi declarada compressão VRAM inexistente.

Resolução adaptativa é opcional e desligada inicialmente. Após acomodação inicial, janelas de 3 s ajustam 2,5 pontos percentuais por vez; recuperação exige 12 s de folga. Limites inferiores: 70/85/90%, sem alterar física. GPU medida tem preferência; se indisponível, usa p95 de frame como aproximação. Pausa/captura bloqueiam ajustes. A suíte `graphics_runner` verifica limites, histerese, perfis e preservação dos ticks físicos.
