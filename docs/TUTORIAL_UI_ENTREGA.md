# Entrega local — tutorial e interface

Implementada uma sala 3D de preparação com nove etapas, usando o jogador, as interações, o esconderijo, a lanterna, o arremesso e o painel reais. O microfone é opcional: a alternativa de demonstração aparece identificada como SIMULAÇÃO. A entrada na fase principal fecha a porta, elimina a cena de preparação e impede o retorno pelo checkpoint. O progresso do treino fica separado da partida.

O HUD recebeu tema e ícones próprios. A mochila mostra imagens renderizadas dos modelos, nomes, quantidades, categorias e ações compatíveis com cada item. Itens essenciais não podem ser descartados. A inspeção usa um único viewport 3D sob demanda; o perfil baixo oferece imagem 2D. Não foram inventadas barras de bateria ou resistência.

## Evidências

- [Resultados consolidados](review/tutorial-ui/validation.json): 693 verificações nativas aprovadas nas doze suítes; microfone físico não exercitado.
- [Navegadores](review/tutorial-ui/browser-results.json): exportação local com toque emulado, mochila, salvamento IndexedDB e recarga.
- [Percurso automatizado Web](review/tutorial-ui/chromium-qa.json): 41 verificações aprovadas e nenhum erro durante o percurso. O encerramento da engine emite dois avisos de texturas de 5.460 bytes e um de WorkerThreadPool, com suas linhas de origem preservadas no log. Essa pendência não foi apresentada como resolvida.
- [Sala e HUD](review/tutorial-ui/preparation.png), [mochila](review/tutorial-ui/backpack.png), [inspeção](review/tutorial-ui/inspection.png).

O teste integrado reposiciona o jogador entre algumas estações; não equivale a uma caminhada manual contínua. Os tempos de requestAnimationFrame registrados nos navegadores são amostras curtas do agendador do navegador, não medições de GPU nem garantia de FPS em celulares.

## Arquivos e limites

Implementação em `scripts/tutorial`, `scenes/tutorial`, `scripts/ui` e `assets/ui`. Integrações em `game.gd`, `main.gd`, `player.gd`, `hud.gd` e `sound.gd`. O reconhecimento de impactos em `physical_prop.gd` agora conserva uma amostra anterior adicional de velocidade para o contato com CCD. Testes e ferramentas estão em `tests/tutorial_*`, `tests/inventory_runner.*`, `tools/tutorial_ui_smoke.cjs` e `tools/art/render_inventory.py`.

Os dez documentos TUTORIAL_* e de HUD/inventário/UI detalham critérios, configurações, transição e testes. Permanecem necessários ensaios em Android/iPhone físicos, Safari, microfone real e desempenho térmico. Esta etapa não gera um novo APK nem valida assinatura ou compilação iOS.

Artefato: `builds/tutorial-ui/ecos-tutorial-ui-web.zip`, acompanhado de manifesto e hash. É uma versão local não publicada. Nenhum envio ao Git ou Cloudflare foi feito nesta etapa; os endereços públicos e o APK atualmente publicado permanecem os mesmos.
