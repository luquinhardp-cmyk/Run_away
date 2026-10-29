# Microfone: implementação e limites

## Pipeline real
`audio/driver/enable_input=true` → consentimento na tela → permissão RECORD_AUDIO no Android → AudioStreamMicrophone → AudioStreamPlayer → bus MicCapture → AudioEffectCapture → cálculo RMS estéreo. O bus fica mudo depois do efeito: não reproduz voz nos alto-falantes. Não usa AudioEffectRecord, escrita de voz em arquivo, reconhecimento de fala ou rede.

As amostras permanecem apenas no ring buffer (0,2 s) e na variável temporária usada no processamento. Após o cálculo, não são retidas. Durante calibração, só valores escalares em dB são guardados por três segundos. Esses valores são descartados ao terminar ou suspender.

## DSP
RMS = raiz da média da energia dos dois canais. dB = 20 log10(RMS), limitado a -80 dB. Suavização exponencial com constante 14/s. Calibração de três segundos, percentil 80 dos valores medidos, piso limitado a [-72, -16] dB. Limiares **iniciais para testes**, relativos ao piso:

| Nível | Excesso sobre piso | Raio / intensidade |
|---|---|---|
| 0 | abaixo de 8 dB | não emite |
| 1 | 8 a <16 dB | 7 m / 0,23 |
| 2 | 16 a <26 dB | 17 m / 0,62 |
| 3 | 26 dB ou mais | 30 m / 1,0 |

O ajuste de sensibilidade desloca a classificação em dB. É necessário sinal sustentado por 120 ms; cooldown de 550 ms evita inundar a IA. Esses parâmetros não foram calibrados com pessoas, ventiladores ou TVs reais. Podem precisar de ajuste por aparelho, especialmente quando o Android aplica AGC. Não há cancelamento de eco ou reconhecimento de voz: recomenda-se fone para evitar realimentação do jogo. Recalibramos a cada retomada após pausa, pois o ambiente pode mudar.

## Ciclo de vida
Padrão desligado. Consentimento é necessário a cada sessão. Android solicita permissão em runtime e trata retorno assíncrono; permissão negada mantém modo sem microfone. Botão no HUD desativa imediatamente. Pausa, derrota, vitória, saída e perda de foco param o stream e limpam buffer/nível. Foco recuperado não retoma o jogo sozinho; exige continuar. Consentimento revogado impede retomada. Ausência de frames/sinal por seis segundos desativa captura e informa modo alternativo.

A engine pode inicializar seu dispositivo de entrada por configuração de projeto; a aplicação só inicia o stream de captura e analisa amostras após consentimento. O comportamento de inicialização do driver e indicador de privacidade do sistema precisa ser verificado por SO/dispositivo.

## Integração com a IA
Eventos são originados **na posição do personagem**; um microfone mono/estéreo do celular não determina a direção física da voz na sala real. A IA aplica distância, oclusão, repetição e seu estado. Ruído forte pode revelar esconderijo e dar início à investigação; perseguição usa visão para confirmar alvo. Sem microfone, passos, corrida, portas, objetos e gerador permanecem ativos.

## Validação pendente
Permissão concedida/negada/revogada, fluxo assíncrono Android, ausência de microfone, indicadores do SO, interrupção por chamada, retorno do segundo plano e medição real de ruído. Testes de RMS por amostras sintéticas não validam entrada física.

Referências: [AudioStreamMicrophone](https://docs.godotengine.org/en/stable/classes/class_audiostreammicrophone.html), [AudioEffectCapture](https://docs.godotengine.org/en/stable/classes/class_audioeffectcapture.html), [OS e permissões](https://docs.godotengine.org/en/stable/classes/class_os.html).
