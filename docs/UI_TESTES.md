# Validação da interface

`tests/inventory_runner.tscn` verifica dados reais, thumbnails, quantidades, seleção, proteção de missão, chave/fechadura, lanterna, descarte físico, inspeção 3D, rotação de toque, zoom, remoção de viewport, fallback 2D, Escape, ausência de reconstrução por frame, ausência de ruído da UI, estado de agachamento, joystick e câmera com dois toques e limpeza na pausa.

`tests/tutorial_persistence.tscn` também verifica os três tamanhos de layout. `tests/tutorial_review.tscn` gera capturas reais em Compatibility, incluindo ambiente, mochila, inspeção e menu de início.

Resultados consolidados e logs: `docs/review/tutorial-ui/validation.json`. O smoke Web gera `browser-results.json` e imagens de abertura, mochila, fechamento e recarga. A validação nativa headless verifica lógica, não desempenho de GPU ou toque físico.

Regressões repetidas: runner, expansion, geometry, graphics, horror, night, physics, received_creature e web_audit. Autenticação Firebase, publicação e assinaturas não foram alteradas ou exercitadas nesta etapa.

Limites: nenhum celular conectado, Safari/iOS físico não disponível, sem calibração de FPS térmico. Não foi feito um benchmark estatístico de custo do novo HUD; verifica-se por teste que a janela não reconstrói slots por frame e usa apenas um viewport de inspeção sob demanda. Consultar os logs para eventuais avisos de encerramento do driver de áudio headless.

Resultado final desta etapa: 693 verificacoes nativas aprovadas, zero falhas; Chromium e Firefox concluiram o smoke da exportacao local com zero erros de console e persistencia confirmada. O QA Web integrado passou 41 verificacoes; seus avisos de encerramento da engine estao preservados em `review/tutorial-ui/chromium-qa.json`. Veja tambem `TUTORIAL_UI_ENTREGA.md`.
