# Otimização de geometria para Android

37 modelos com dois exports cada; o manifesto registra triângulos e materiais. Importação Godot também gera LODs automáticos de malha. ModelLibrary reutiliza PackedScenes/materiais; decoração estática é mesclada espacialmente. Árvores usam MultiMesh, culling e geometrias mais simples ao longe. A floresta mantém Lua/estrelas/horizonte nos três perfis; não troca identidade visual por um fundo vazio.

Baixo seleciona exports leves ao criar o mundo e texturas reduzidas; médio usa modelos normais para objetos próximos e árvores próximas leves; alto permite árvores próximas normais e sombras lunares. O LOD de cena é escolhido ao iniciar a sessão; mudar o perfil durante a sessão atualiza materiais/efeitos e os LODs automáticos da engine continuam ativos, mas não reconstrói todos os visuais já instanciados. Reinicie a sessão para comparar o orçamento completo de cada perfil. Objetos interativos não desaparecem arbitrariamente por distância curta.

Orçamentos de trabalho, sujeitos a validação real: itens pequenos geralmente abaixo de 3 mil triângulos; equipamentos detalhados abaixo de 10 mil; árvores próximas abaixo de 10 mil no alto e cerca de metade no leve. Objetos distantes, raízes não interativas e copas não recebem corpos físicos individuais. Máximo de objetos físicos ativos da versão anterior é preservado. Evitam-se sombras novas de luzes locais, transparências empilhadas e subdivisão desnecessária.

Profiling reproduzível: `tests/geometry_review.tscn`, Godot 4.7.2 Compatibility/Intel UHD, viewport 1280×720, perfil médio e escala 3D de 0,85. `docs/review/geometry/metrics.json` registra draw calls e primitivas por vista; `before/metrics.json` registra a 0.7 na mesma câmera. Valores variam muito entre sala, corredor e exterior por luzes/culling. Não são FPS nem medições de GPU Android. As vistas amplas do corredor merecem atenção em dispositivos modestos; usar baixo/médio é a recomendação inicial.

229 testes de geometria/integração e 293 dos demais sistemas totalizam **522 aprovados**. Incluem normais, UVs, materiais, LODs, dimensões, porta/batente, gaveta, suporte dos itens, colisão da janela, terreno, física, IA, objetivos, gráficos, captura e checkpoint. Microfone automatizado usa sinais simulados; não valida captação acústica real. Nenhuma regra de Firebase foi alterada.

Os contadores de geometria acima precedem a revisão gráfica final. A versão 0.8 usa escala média 100%, MSAA 2× e sombras da lanterna, com custo maior; ver [comparativo medido](COMPARATIVO_DESEMPENHO.md) e [configurações atuais](OTIMIZACAO_ANDROID.md).

Pendências obrigatórias antes de prometer desempenho mobile: ARM64 real, Mobile/Vulkan em GPU de aparelho, FPS sustentado em cada sala/perfil, memória e carregamento, temperatura/bateria, toque multitoque, leitura da tela e microfone com alto-falante/fones. Ainda há draw calls de múltiplos materiais e iluminação local; material/malha não bastam para garantir fluidez.
