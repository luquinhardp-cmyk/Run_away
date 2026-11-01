# Canvas, tela cheia e orientação

`hosting/web-platform.js`, copiado e injetado por `hosting/prepare.py`, ajusta canvas/body à área visível, sem margens ou scroll externo. Usa visualViewport quando disponível e `viewport-fit=cover`. Os insets CSS de área segura são repassados para `IndustrialUI.insets` e HUD; uma faixa é reservada para o botão Web de fullscreen, separada de pausa e microfone.

A engine só inicia após a escolha de entrada, para que a compilação inicial não bloqueie esse botão. A entrada oferece ENTRAR NO JOGO (solicita fullscreen por gesto) e CONTINUAR EM JANELA. O mesmo botão de cantos permite entrar/sair. Ausência da API ou rejeição mostra mensagem breve e mantém o modo janela. Landscape é solicitado somente após fullscreen permitido; falha orienta a rotação manual. Não há promessa de fullscreen ou bloqueio automático no iPhone.

Em dispositivo com toque/ponteiro grosso e viewport vertical, a tela GIRE SEU CELULAR impede interações acidentais. Ela desaparece em paisagem. `scripts/ui/web_platform.gd` pausa a partida ao girar para vertical ou ocultar a aba; o jogador continua pelo menu ao retornar. Não recarrega a cena nem recria áudio ao redimensionar. Os caminhos Android/iOS nativos continuam usando as configurações de exportação e safe area existentes.

Validação em Chromium: entrada/saída de fullscreen, recusa tratada, modo janela, vertical/horizontal e estado preservado no teste do wrapper. O smoke da fase real registra rotação e mochila. Eventos de toque e dispositivo de áudio são emulados; Safari/iPhone físico permanece pendente.

Referências: [ScreenOrientation.lock](https://developer.mozilla.org/en-US/docs/Web/API/ScreenOrientation/lock), [orientação da tela](https://developer.mozilla.org/en-US/docs/Web/API/CSS_Object_Model/Managing_screen_orientation). APIs limitadas são tratadas como opcionais.
