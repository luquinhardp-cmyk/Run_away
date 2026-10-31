# Auditoria Web — 31/10/2026

Branch de trabalho: `feature/ios-support`, base `a01f532`. Motor executado: Godot 4.7.2, Web Compatibility/WebGL 2, exportação sem threads e sem GDExtension. Android continua Mobile. Não houve publicação.

Foram inspecionados carregador, cabeçalhos, exportação, construção do mapa, navegação, renderização, floresta, áudio, microfone, controles e persistência. A comparação do carregador usa **o mesmo pacote 0.9.0**, mesma resolução 960×540 e Chromium com ANGLE/D3D11, em processos separados. A comparação não representa Android nem Safari.

Evidências: [comparação](review/web-audit/comparison.json), [antes](review/web-audit/before.json), [depois](review/web-audit/after.json), [etapas do cenário](review/web-audit/startup.json). Os buffers contabilizados são retornos de `Response.arrayBuffer`, não memória residente total, pico de RAM ou heap WASM.

Leia [erros e pendências](WEB_ERROS_ENCONTRADOS.md), [correções](WEB_CORRECOES_IMPLEMENTADAS.md) e [desempenho](WEB_PERFORMANCE.md). A auditoria não declara eliminados todos os bloqueios: o primeiro desenho da fase ainda precisa de investigação de shaders/driver. Não foi comprovada compatibilidade em iPhone/iPad.

Foi também reproduzida e corrigida a perda da opção de retomada após recarga: o arquivo existia no IndexedDB, mas `2.0`, produzido pelo parser JSON, era rejeitado por uma comparação de array com inteiros. A validação agora aceita apenas versões numéricas exatamente 1 ou 2. Testes de regressão totalizam **617 aprovados e zero falhas**. Compare `chrome-reload-before-savefix.png` com `chrome-release-reload.png` na pasta de evidências.

O artefato final passou por abertura, partida, pausa, persistência e recarga em Chrome 156, Edge 156 e Firefox 157, com zero erros registrados e opção de continuar visível. Isso não valida Safari nem aparelhos físicos. Entrega empacotada em `builds/web-audit/ecos-web-audit.zip`, sem publicação. Os hashes em `artifact.json` e `source-manifest.json` identificam o artefato e as fontes modificadas, pois a base Git ainda contém alterações locais.

Para testar o artefato local a partir da raiz do repositório: `python -m http.server 8080 --directory builds/web-audit/release`, depois abrir `http://localhost:8080/play/`. Abrir index.html diretamente pelo sistema de arquivos não é equivalente a servir o jogo.

Reprodução do benchmark: `python tools/build_web_audit.py --godot CAMINHO_DO_GODOT` e `node tools/web_audit_scenarios.cjs`. O runner Node aceita `PLAYWRIGHT_MODULE` para apontar a uma instalação do Playwright. Smoke do artefato de produção local: `node tools/web_audit_smoke.cjs` (Chrome/Edge instalados e Firefox do Playwright). Nenhum desses comandos publica o jogo.
