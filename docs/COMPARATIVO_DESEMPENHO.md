# Comparativo de desempenho

Ensaio desktop Intel UHD, Godot 4.7.2 Compatibility, janela 1280x720, VSync desligado e FPS sem limite exclusivamente no benchmark. Antes: geometria b62623d, medio 85%, sem MSAA/sombra da lanterna. Depois: medio 100%, MSAA 2x, sombra da lanterna e mipmaps. Portanto a tabela compara configuracoes visuais diferentes e nao isola uma otimizacao. Mais qualidade custou desempenho; nao houve ganho geral de FPS.

| Cenario | FPS antes | FPS depois | p95 antes (ms) | p95 depois (ms) |
|---|---:|---:|---:|---:|
| room | 119.3 | 110.3 | 9.74 | 10.22 |
| corridor | 94.2 | 86.9 | 12.69 | 14.40 |
| forest | 108.4 | 80.9 | 11.88 | 14.62 |
| moon | 125.9 | 96.7 | 10.54 | 11.74 |
| flying_shadow | 120.3 | 72.6 | 10.95 | 15.29 |
| chase | 97.8 | 58.0 | 11.71 | 14.30 |
| falling_props | 119.1 | 61.9 | 10.90 | 12.37 |
| microphone_simulated | 90.1 | 88.0 | 12.69 | 15.03 |
| steady_exploration | 107.9 | 89.7 | 12.00 | 15.59 |
| capture | 93.0 | 98.0 | 11.76 | 12.70 |

Texturas no cenario room: 40.7 para 49.7 MiB. A memoria adicional dos mipmaps e o custo de sombras/AA devem entrar no orcamento do dispositivo. Dados brutos incluem GPU medida, tempo fisico, IA, memoria, consultas e frames maximos; CPU e GPU nao devem ser somados como tempos sequenciais.

Na floresta, consultas de teto cairam de 111.7 para 4.0/s; durante voo, de 242.6 para 3.3/s. Isso demonstra a reducao de consultas, sem prometer ganho de FPS proporcional.

Baixo e alto foram medidos separadamente, mesmos dez cenarios, com exploracao de 8 s; medio e referencia usam 60 s. Os arquivos after_q0/after_q1/after_q2.json sao a evidencia. Nao sao testes termicos prolongados. Alto inclui picos severos de frame em quedas/compilacao inicial e nao sustenta 60 FPS em todas as vistas deste computador. Nao ocultar esses picos por medias globais.

O ensaio sharpness.json compara 85/100/170% com a mesma camera e MSAA 2x. Dobrar a escala linear de .85 para 1.7 quadruplica pixels internos e reduz FPS; nao foi adotado como padrao. Imagens sharpness_*.png permitem revisao visual. A captura foi refinada visualmente depois da primeira medicao; capture_closeup.png e os testes de horror verificam o enquadramento final.

Microfone: RMS sintetico de 2048 amostras, sem entrada fisica. Android: nenhum aparelho conectado, sem certificacao de FPS, calor, bateria, latencia, toque ou atualizacao instalada. O benchmark pode ser repetido com --quality 0/1/2 --steady 60 --uncapped; variabilidade, carregamento inicial e outras cargas do sistema afetam resultados.
