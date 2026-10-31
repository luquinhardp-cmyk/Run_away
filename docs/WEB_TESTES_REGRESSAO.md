# Testes de regressão

Executados no Godot 4.7.2 headless: runner, expansion_runner, geometry_runner, graphics_runner, horror_runner, night_runner, physics_runner, received_creature_runner e web_audit_runner. Logs em `.tools/web-audit-*.log` na raiz do workspace; resumo consolidado em `review/web-audit/regression.json`.

Resultado consolidado atualizado em `regression.json`. A execução inicial teve 614 aprovados, zero falhas; depois foram adicionados três testes de persistência e repetidas as suítes afetadas. O benchmark Web completou os 12 cenários, incluindo captura válida, com zero erros.

Cobrem progressão, fuga, reação da IA, rotas de navegação, portas, física, perfis, céu/floresta, criatura e captura. Testes headless são lógicos; não comprovam visual, toque físico, microfone real ou desempenho de celulares.

Node: `node tests/hosting_loader_test.cjs`. Cobre gzip bruto/simples/duplo, partes, falhas, cabeçalho fragmentado, WASM.compileStreaming, gzip truncado, contrapressão e cancelamento.

Chromium: jogo Web 0.9.0 com carregador antigo/novo; início, gameplay e pausa, zero erros registrados. Benchmark Web controlado separado em `scenarios.json`.

Artefato final local: Chrome 156, Edge 156 e Firefox 157 completaram abertura, início de fase sem microfone, pausa, checkpoint no IndexedDB e recarga, com zero erros registrados. Inspeção visual das três capturas após recarga confirmou “CONTINUAR DO CHECKPOINT”. Evidência em `release-browsers.json` e imagens `*-release-reload.png`. Não foi automatizada uma fuga completa pela UI nesses navegadores.

O primeiro ensaio encontrou o bug de leitura do checkpoint. Seu relatório foi preservado em `release-before-savefix.json`. Nesse ensaio o Firefox também teve erro WASM numa recarga durante reexportação local; o ensaio final usou um artefato fixo e não reproduziu esse erro. Avisos de autoplay antes do gesto e de pipeline WebGL no Firefox estão nos logs, não são contados como erros de execução.

Safari, Android físico, iPhone e iPad continuam pendentes. Autorização Web real de microfone, modo privado, armazenamento negado, longa duração e regressão nativa precisam de ensaios específicos.
