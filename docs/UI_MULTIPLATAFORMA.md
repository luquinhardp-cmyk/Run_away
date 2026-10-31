# Interface multiplataforma

Mesma implementação GDScript/Control em Web, Android e iOS. HUD recalcula posições ao redimensionar e usa safe area nativa para margens de ações, joystick, objetivo, microfone e pausa. Escala/opacidade/posição dos controles seguem configurações existentes.

Mochila usa cabeçalho fixo com fechar, conteúdo rolável e grade responsiva. Telas estreitas ou verticais usam uma coluna, com quantidade de slots por linha reduzida. Testes de layout cobrem 1280×720, 960×540 e 720×1280. A orientação do jogo continua a existente; o teste vertical exercita layout e não altera a orientação de exportação.

Mouse, scroll, Tab/Escape e toque em botões são suportados. A inspeção aceita arraste de mouse ou dedo e botões de zoom. O teste de multitouch verifica joystick e câmera independentes e limpeza ao pausar. Esses eventos são sintéticos; não substituem teste em aparelhos.

A mochila fica numa CanvasLayer própria acima do HUD e recebe entrada mesmo com o mundo pausado. Cursor é liberado durante a navegação. No Web, recaptura de mouse requer gesto permitido; o jogo não tenta forçar pointer lock ao fechar por Escape.

O áudio da interface é baixo e não emite NoiseBus. Sons produzidos por ações reais, como porta e objeto descartado, continuam pertencendo ao mundo. As permissões e limitações do microfone permanecem as documentadas na auditoria Web.

Não houve publicação, alteração de links, identidade de pacote Android ou assinatura. Android/iOS físicos e Safari permanecem sem validação neste ambiente.
