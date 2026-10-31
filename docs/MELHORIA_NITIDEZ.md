# Nitidez

As causas encontradas foram resolução interna reduzida, ausência de MSAA e mipmaps inconsistentes. A identidade escura do jogo exige preservar contraste da lanterna; aumentar brilho global não resolve serrilhado nem definição.

Baixo usa 80% sem MSAA; médio 100% com MSAA 2×; alto 100% com MSAA 4×. Materiais usam filtragem linear com mipmaps, anisotrópica nos perfis médio/alto. A interface permanece na resolução de saída. Não foi aplicado blur, TAA ou sharpen agressivo. As texturas existentes continuam 256/512 onde apropriado; não foram infladas para 4K.

O ensaio `tests/sharpness_review.tscn` compara a mesma câmera em 85%, 100% e 170%, com screenshots e FPS desktop em `review/performance/sharpness*`. Dobrar de 85 para 170% reduz pela metade o espaçamento linear de amostragem, com quatro vezes mais pixels internos; não significa duplicar detalhes da textura nem garantir melhora perceptual de 50%. A opção de 170% é manual, de alto consumo, e não o padrão para celular.

O resultado visual depende da resolução física, do renderer e do hardware. Desempenho em Android e comparação em tela física continuam pendentes. Os mipmaps reduzem cintilação à distância, com custo de memória; não aumentam a resolução fonte de uma superfície próxima.
