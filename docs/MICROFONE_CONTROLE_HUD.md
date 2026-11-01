# Controle real do microfone

O botão existente só desligava e ficava indisponível sem consentimento. Agora permite solicitar permissão, cancelar uma solicitação pendente, ligar novamente e desligar. Há SVGs próprios para ligado, cortado, permissão e indisponibilidade, status e medidor reais. A API indisponível desabilita o botão e explica a exigência de HTTPS/suporte a áudio; falhas transitórias permitem nova tentativa.

Android/iOS nativos continuam com AudioStreamMicrophone e AudioEffectCapture; a captura para ao suspender. A resposta de permissão Android não reativa a entrada se o usuário já cancelou.

Na Web, o bridge usa getUserMedia somente após solicitação. Um AnalyserNode calcula RMS/dB local a cada 50 ms; apenas o número chega ao GDScript. Um ganho zero impede monitoramento. O processamento usa a mesma calibração, gate e NoiseBus já existentes, sem gravar, armazenar ou transmitir voz. O contexto da captura é separado da reprodução do jogo.

Desligar/suspender encerra todas as MediaStreamTracks, desconecta nós, fecha o contexto dedicado, zera intensidade e invalida a solicitação em andamento. Se uma autorização chegar após cancelamento, suas tracks são imediatamente encerradas. Aba oculta, interrupção do dispositivo, pausa, mochila e saída do jogo também suspendem. Retorno depende da continuação explícita da partida; não há gravação escondida em background.

Desligar o microfone não desliga NoiseBus: passos, portas e impactos continuam audíveis para a criatura. O teste emite um evento real de passos com Mic desativado e exige sua propagação.

`node tests/web_platform_test.cjs` usa um dispositivo sintético do Chromium para testar captura, parada, negação, cancelamento tardio, interrupção e visibilidade. O smoke da fase aciona o botão real do HUD, aguarda a captura e verifica as tracks encerradas ao desligar. Não representa um microfone físico de celular.

Referências: [getUserMedia](https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia), [MediaStreamTrack.stop](https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/stop). As permissões dependem do navegador e do contexto seguro.
