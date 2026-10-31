# Otimização e validação 0.7

Sky único com estrelas no shader, textura lunar 512²; MultiMeshes por setor, três malhas arbóreas reutilizadas, horizonte contínuo, colisores simples e vento por vértice. Sem volumetria, objetos individuais de estrelas ou física de folhas. Uma criatura alada, dois LODs (1.192/654 triângulos), três vozes aéreas e três da floresta. Recursos inativos são ocultos; visibilidade de camadas intermediárias reduzida no baixo/médio. Lua/floresta permanecem em todos os perfis.

Captura desktop Compatibility, Intel UHD Graphics, 1280×720, mesma câmera: baixo 27 draw calls/212.618 primitivas; médio 27/264.218; alto 109/1.286.382. Alto habilita sombras lunares, ampliando renderização. São contadores de uma vista desktop, não FPS Android nem garantia de orçamento em todo o mapa. Recomenda-se começar em baixo/médio em celulares modestos.

Testes executados: 76 ambiente, 79 regressão, 41 expansão, 23 horror, 47 física: **266 aprovados, zero falhas**. Executar cenas `tests/night_runner.tscn`, `runner.tscn`, `expansion_runner.tscn`, `horror_runner.tscn`, `physics_runner.tscn` com `--headless --path .`. Revisão visual: `tests/night_review.tscn` sem headless, Compatibility. Imagens em `docs/review/night/`.

Preservados: câmera/FPS, touchscreen, lanterna, leitura de intensidade do microfone, IA terrestre, física/interações, objetivos, menus e formato de checkpoint. Nenhuma regra/configuração de Firebase modificada. Testes desta entrega não repetem os 20 testes remotos de Firebase da 0.6; validação automática de fluxo não substitui toque/microfone reais.

Prévia web 0.7 verificada em Chrome por software: carregamento, consentimento, jogo, pausa, cadastro e importação do checkpoint físico para Firestore passaram sem erros de execução. Captura por software precisou de timeout maior; não representa FPS em aparelho. Produção confirmada em 0.3.0. APK remoto respondeu HTTP 200, com 47.402.155 bytes e assinatura local v2/v3 validada.

Pendências: dispositivos Android físicos, renderizador Mobile/Vulkan em GPU real, FPS sustentado, temperatura, bateria, qualidade de áudio, ergonomia e brilho em múltiplas telas. As árvores são procedurais simplificadas, sem impostors de imagens ou LOD individual progressivo; a redução é por instâncias/culling e horizonte. Névoa de profundidade, sem partículas de poeira/folhas nem névoa volumétrica. Não há segunda IA de perseguição aérea.
