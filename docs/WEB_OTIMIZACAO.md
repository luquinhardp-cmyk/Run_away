# Diagnóstico e otimizações Web

Foram preservados física essencial, estados/sensores da IA, floresta, lua, criaturas, lanterna, objetivos e áudio. Física já tinha limites de corpos acordados, sleeping, congelamento de itens secundários distantes e limpeza de objetos fora do mapa. IA já limitava percepção/pathfinding. Não foram desligados para fabricar ganho de FPS.

Problemas encontrados: reconfiguração de todos os materiais PBR em notificações de qualidade sem mudança; dezenas de cópias idênticas do material dos troncos; construção síncrona do complexo; shaders de normal triplanar e criatura/sombras aparecendo pela primeira vez durante o percurso. Hospedagem mantém o carregador gzip/WASM já validado; o benchmark não usa a conexão pública para isolar renderização e scripts.

Correções:

- `HorrorArt.set_quality` retorna imediatamente sem alterações; o teste exige zero reescritas em 20 chamadas idênticas.
- Floresta compartilha um material de tronco entre chunks, mantendo MultiMesh, horizonte, população e culling.
- Materiais da criatura são reutilizados por perfil. Troca médio/alto agora atualiza apresentação corretamente, preservando captura ativa.
- Web médio evita normal triplanar na arquitetura e normal/sombra projetada da criatura; objetos próximos com UV mantêm seus materiais. Web alto conserva essas opções. Baixo mantém lua/floresta e física completa.
- O carregamento Web de produção distribui tiles e etapas entre frames e mostra o estágio real. Uma câmera temporária desenha os estágios atrás da tela de carregamento, antecipando materiais visíveis; controles e IA só são liberados depois dos primeiros frames. SceneTree permanece na thread principal. Nenhum jogador/IA entra antes de a construção e o bake terminarem. Tempo de carregamento não é contado como tempo de fuga nem aciona autosave de fase incompleta.

O menu oferece WEB BAIXO, WEB MÉDIO e WEB ALTO, com preferência persistente. Navegador móvel novo começa em baixo, sem substituir escolha já salva. Metas são 30 FPS no baixo e até 60 nos demais conforme hardware; resolução, MSAA, sombras e distância continuam usando os controles existentes. A troca não reduz frequência da física.

## Medição, sem promessa de benchmark universal

Mesma máquina Windows/Intel UHD, Chromium headless WebGL/ANGLE, 960×540, seed e percurso controlados, perfil médio, uma execução antes e uma depois. Cache do driver e concorrência de ferramentas impedem atribuir causalidade exclusiva. Não é teste térmico ou amostra estatística; GPU timing não estava disponível.

| Cenário | p95 antes (ms) | p95 depois (ms) | Maior frame depois (ms) |
| --- | ---: | ---: | ---: |
| Sala | 18,0 | 17,9 | 19,6 |
| Corredor | 26,8 | 29,4 | 35,3 |
| Floresta | 17,8 | 17,8 | 41,7 |
| Perseguição | 1.471,2 | 33,4 | 593,7 |
| Objetos em queda | 44,6 | 23,8 | 769,9 |
| Exploração curta | 25,6 | 28,4 | 31,8 |

Construção síncrona do benchmark: 2.174,4 → 2.182,3 ms, sem melhora demonstrada. Esse fixture usa Game.testing e não exercita o carregamento escalonado de produção; este possui teste próprio. O p95 da perseguição melhorou nesta execução, mas há picos graves restantes e alguns cenários pioraram. Não declarar 30 FPS universais ou congelamentos totalmente eliminados. A amostra curta de rAF no smoke baixo também não é medição de GPU.

Dados completos: `review/stability/{before,after}/scenarios.json` e `startup.json`. Incluem memória de texturas, draw calls, primitivas, física, CPU, raycasts e marcação de microfone sintético. Pendências: primeiro desenho/compilação em driver frio, aparelhos reais, sessões longas e iOS/Safari.
