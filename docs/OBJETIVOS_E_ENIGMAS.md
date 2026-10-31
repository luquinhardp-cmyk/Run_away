# Objetivos, enigmas e persistência

`HorrorObjective` Resources definem ID, texto, pré-requisitos e objetivo opcional. `HorrorObjectives` deriva LOCKED, AVAILABLE, ACTIVE e COMPLETE do estado real, sem flags duplicadas que possam contradizer inventário. Game mantém esse componente, sem novo autoload. HUD consulta o objetivo disponível atual.

Fluxo: lanterna na enfermaria → fusível na manutenção → instalar no painel da sala de energia → acionar gerador ao lado → cartão da segurança → saída de serviço. O painel não aceita instalação sem componente. O gerador recusa ativação antes da instalação, emite ruído forte e altera luzes/fechaduras. O cartão exige energia mesmo acessado por rota alternativa. Vitória exige energia e cartão. Captura leva à derrota e ao resumo de pontos/tempo existentes.

Objetivo opcional: encontrar a chave no depósito e liberar a oficina. A chave não abre a segurança. Componentes não se duplicam. A instalação não remove o fusível do inventário, preservando compatibilidade com pontuação e saves anteriores.

Checkpoint **v2** acrescenta `world`: seed, variante, dificuldade, desbloqueios, eventos, painel, gerador iniciado, apagão, peças disponíveis/coletadas e vitória. Inventário, portas e tempo mantêm seus campos anteriores. Saves v1 continuam aceitos; energia já restaurada migra para painel/gerador prontos. Retomar continua na enfermaria, preservando mecanismos, eventos e a configuração da partida. Corpos arremessados ativos não são serializados; consumo é persistente.

Pontuação preservada: 100 por cada um dos três itens principais, 300 por já ter restaurado o gerador e 500 pela fuga. Chave e peças não alteram a fórmula. Um apagão posterior não apaga os 300 pontos conquistados. A regra de `runs.power` representa restauração já atingida, enquanto `checkpoint.power` representa o estado elétrico atual.

`firestore.rules` aceita v1/v2 e a chave opcional, mantendo isolamento por UID, resultados imutáveis e commits atômicos. Regras e cliente devem ser atualizados em conjunto ao publicar uma versão com novos campos. Nenhum áudio ou informação direcional de microfone é persistido.
