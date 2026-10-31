# Otimização e validação Android da expansão

Preservados: renderer Mobile no APK, Compatibility na Web, mapas 256/512, LOD articulado, batching espacial de arquitetura e número limitado de sombras. IA faz visão a cada 0,18 s; audição usa até três raios por evento. Busca gera no máximo dez pontos por entrada de estado e guarda histórico limitado. Repetição da mesma fonte não reinicia a escuta indefinidamente.

Física: no máximo oito arremessáveis, colisão simples, CCD e vida de 18 s. Áudio de efeitos tem cache de clips e limite de 24 vozes geradas; rádio/alarme usam um player por dispositivo e desligamento automático. Navegação não é reconstruída por frame: apenas mudança de bloqueio e obstáculo físico, com agrupamento de solicitações. O bake síncrono ainda precisa de medição em aparelho.

Em CONFIGURAÇÕES, habilitar métricas locais salva `user://expansion_metrics.json`, com amostra de FPS, pior frame da janela, tempo de processamento, último custo de IA em microssegundos, custo de criar áudio, custo RMS, latência de saída, raycasts sonoros/s, corpos ativos, nós, memória estática e draw calls. Latência de saída **não é custo de CPU de áudio**. São diagnósticos da sessão, não telemetria remota. Desabilitado por padrão. Exportar esse JSON com modelo do aparelho, renderer/perfil e trecho jogado para comparação.

Meta de 30 FPS em dispositivos modestos continua uma meta. Testes headless comprovam regras, física e navegação, mas não certificam FPS, calor ou bateria. Nenhum Android foi conectado. Testar fisicamente: instalação ARM64, permissões concedida/negada, fones/alto-falante, multitouch com arremesso, background/retomada, 10–15 minutos de perseguição, temperaturas, bateria e proporções de tela. O checklist anterior `TESTES_ANDROID.md` continua aplicável.

Builds de revisão devem usar `builds/expansion/`, mantendo os builds anteriores separados. Preset Android conserva RECORD_AUDIO e INTERNET. Não publicar em lojas nem substituir hosting de produção durante revisão local.
