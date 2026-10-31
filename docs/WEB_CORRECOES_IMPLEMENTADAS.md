# Correções implementadas

- `hosting/wasm-loader.js`: descompressão em fluxo, cabeçalho gzip dividido entre chunks, até duas camadas, MIME WASM, remoção de Content-Length inválido, partes sequenciais, propagação de falhas e cancelamento.
- `scripts/audio/microphone.gd`: extração do processamento de amostras; silêncio digital não desliga o dispositivo. O timeout sem amostras permanece.
- `scripts/systems/facility.gd`: agrupa solicitações de navegação durante construção; bake único após arte, eventos restaurados, floresta e física. Mudanças de portas e tubulação continuam solicitando novas malhas. Tempos de construção ficam disponíveis em `startup_ms`.
- `scripts/player/hud.gd`: recalcula layout ao redimensionar; converte safe area usando o tamanho atual e inclui iOS.
- `scripts/systems/game.gd`: valida versões 1/2 também após leitura JSON (que produz floats). Corrige retomada de checkpoint local/conta; rejeita valores inválidos.
- `tests/performance_review.gd`: relatório JSON no console Web e dois cenários de lanterna adicionais.
- `scripts/systems/main.gd`: não solicita pointer lock quando Game.testing está ativo; evita erro de gesto em benchmark automático. O jogo normal continua solicitando captura do mouse.
- `tools/build_web_audit.py`: exportação isolada de diagnóstico; não altera a cena principal de produção nem publica arquivos.
- `export_presets.cfg`: exclui recursos de builds anteriores dos quatro presets; adiciona preset iOS sem preencher identidade Apple.
- `scripts/environment/flying_shadow_event.gd`: a silhueta distante usa material sem iluminação e sem projetar sombras apenas na Web; mantém transparência, voo, áudio e modelo.

As malhas, texturas, floresta, céu, IA, captura, controles e frequência da física não foram removidos ou simplificados nesta etapa.
