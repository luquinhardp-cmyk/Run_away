# Testes do tutorial

`tests/tutorial_runner.tscn` executa ações reais: movimento físico, mira por raycast, coleta, fechadura, lanterna, bloqueio em pé, passagem agachada, corrida, esconderijo, demonstração opcional, projétil, impacto, painel, confirmação e travessia. Também verifica remoção da cena anterior, isolamento dos itens e reinício sem retorno. Entre algumas estações o teste reposiciona o jogador; não apresentar esse percurso automatizado como uma caminhada contínua sem reposicionamentos.

`tests/tutorial_persistence.tscn` verifica ida e volta JSON, inventário/quantidades de treino, armário aberto, separação de checkpoint, menu após a fronteira de entrada e novo tutorial limpo. O teste usa perfil temporário e remove apenas seu próprio arquivo.

Resultados, logs e limitações estão em `docs/review/tutorial-ui/validation.json`. O exercício do microfone nos testes é a alternativa simulada; não houve captação física em celular. Eventos reais de impacto são exigidos para avançar.

O smoke Web `node tools/tutorial_ui_smoke.cjs` serve somente o artefato local em `builds/tutorial-ui/site`, usa eventos de toque emulados, abre/fecha a mochila e verifica arquivo de tutorial no IndexedDB e menu após recarga. Não publica o jogo.

Não foram testados aparelhos Android, iPhone/iPad ou Safari. iOS ainda depende da compilação/assinatura e ensaios no Mac já documentados. Não há promessa de FPS ou ausência absoluta de softlocks em hardware não testado.

Resultado final desta etapa: 693 verificacoes nativas aprovadas, zero falhas; Chromium e Firefox concluiram o smoke da exportacao local com zero erros de console e persistencia confirmada. O QA Web integrado passou 41 verificacoes; seus avisos de encerramento da engine estao preservados em `review/tutorial-ui/chromium-qa.json`. Veja tambem `TUTORIAL_UI_ENTREGA.md`.
