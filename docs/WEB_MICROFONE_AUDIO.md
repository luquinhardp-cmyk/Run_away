# Microfone e áudio Web

O jogo usa AudioStreamMicrophone com captura STREAM em barramento mutado. Processa RMS local; amostras não são enviadas ao Firebase. Permissão e dispositivo dependem do navegador e de contexto seguro (HTTPS ou localhost). O modo sem microfone continua disponível.

Corrigido o desligamento após silêncio digital: receber amostras de valor zero é um fluxo válido. Teste sintético cobre dez segundos de silêncio, calibração, som posterior e desligamento explícito. Não equivale a ensaio com microfone físico.

Permanece o timeout de seis segundos **sem amostras**. Um prompt de permissão demorado pode ultrapassá-lo; ainda é necessário implementar e testar estados explícitos de autorização Web, recusa e indisponibilidade. Não declarar esse fluxo completamente validado.

Pausa/foco continuam suspendendo captura. Não se alterou globalmente áudio para Sample, pois captura e efeitos do projeto precisam de STREAM. Picos, latência, eco e interrupções de áudio exigem teste com fones e aparelhos reais.
