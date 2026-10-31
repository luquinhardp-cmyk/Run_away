# Microfone e balanceamento

O serviço real existente foi preservado: AudioStreamMicrophone → bus MicCapture → AudioEffectCapture → RMS estéreo → suavização. O bus fica mudo para não reproduzir o áudio capturado. Há consentimento explícito, permissão Android, três segundos de calibração (percentil 80), sensibilidade salva, indicador de intensidade, botão de desligar, pausa/foco/background e modo sem microfone. Falta de sinal desliga a captura com mensagem.

Novidades: gate abre a +9 dB sobre o piso e fecha abaixo de +6 dB; níveis médios/altos mantêm margens de histerese. Após três segundos de sinal estável, o piso se adapta lentamente (0,12/s). Assim um ventilador constante tende a deixar de produzir alertas contínuos, enquanto variações rápidas continuam perigosas. Eventos mantêm duração mínima e cooldown de 0,55 s.

Efeitos próximos e fortes conhecidos ativam uma guarda de 0,25 s contra alertas baixos/médios recaptados. Alertas altos continuam válidos. Isso reduz alguns falsos positivos e **não é cancelamento de eco**; rádio contínuo e alto-falante ainda podem contaminar a leitura. Usar fones, calibrar em silêncio e ajustar sensibilidade continua recomendado. Não há reconhecimento de voz nem localização física do som. O estímulo nasce na posição do personagem, inclusive em armário.

Testes sintéticos verificam RMS, classificação, gate, adaptação estável, pausa e background. Microfone físico, diferenças entre fabricantes, latência acústica e falsos positivos em ambiente real continuam pendentes: `adb devices` não encontrou dispositivo nesta sessão. Não há gravação nem transmissão de áudio.
