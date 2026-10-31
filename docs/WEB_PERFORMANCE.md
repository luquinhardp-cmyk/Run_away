# Medição Web

O controle e a alteração do carregador usam pacote idêntico, servidor HTTP local, Chromium headless com ANGLE/D3D11, janela 960×540, contexto novo por execução. Apenas uma execução de cada: variação de cache/driver impede conclusões estatísticas.

| Métrica | Antes | Depois |
| --- | ---: | ---: |
| Bytes retornados por arrayBuffer | 175.183.652 | 34.237.192 |
| Abertura até marcador da engine + espera de 2 s | 8.631 ms | 10.797 ms |
| Maior intervalo rAF, incluindo carregamento da fase | 20.565,8 ms | 19.832,5 ms |
| p95 de rAF do ensaio inteiro | 66,7 ms | 50,0 ms |
| Erros de console registrados | 0 | 0 |

Houve redução de **80,5% nos bytes intermediários contabilizados**, sem ganho comprovado de velocidade de abertura. Os tempos rAF misturam menu, transição e partida e **não são FPS estáveis de gameplay**.

O benchmark separado em `review/web-audit/scenarios.json` executa sala, corredor, floresta, lua, lanterna desligada/ligada, vulto alado, perseguição, objetos em queda, RMS sintético, exploração e captura. Usa posicionamentos controlados, seed 70421, qualidade média e captura/voo forçados. O microfone é sintético. A exploração é curta e não constitui teste de longa duração ou desempenho térmico.

GPU timing pode não estar disponível no WebGL. Zero nessa métrica significa indisponível, não GPU gratuita. Não há medição física em Android, iPhone ou iPad. Profiling do bloqueio no primeiro desenho e repetição em hardware real continuam pendentes.

O primeiro benchmark expôs um bloqueio de 8.183,8 ms na estreia da silhueta alada. Com material Web sem iluminação/sombras, a repetição teve maior frame de 325,2 ms e p95 de 22,2 ms nesse cenário. Houve também correção da espera pela física no teste de captura; a repetição confirma `capture_started=true`, `flying_started=true` e zero erros de console. O primeiro relatório fica em `scenarios-first.json`; o final em `scenarios.json`. Uma execução por configuração não isola totalmente cache de shaders/driver: não atribuir uma redução garantida exclusivamente ao material.

Na execução final controlada, a construção medida por `main.start` levou 2.193,2 ms. Isso não inclui toda a compilação/desenho posterior. A sala ficou com p95 de 17,5 ms, corredor 24,0 ms, floresta 18,1 ms, perseguição 26,4 ms e captura 19,3 ms. São medições desta máquina, não metas garantidas de celular.
