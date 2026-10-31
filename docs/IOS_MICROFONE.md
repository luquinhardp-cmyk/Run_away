# Microfone iOS

Preset inclui `privacy/microphone_usage_description` em português para o uso opcional do microfone na audição da criatura. A mesma captura local RMS continua sendo usada; nenhum áudio é enviado.

Não se adicionou chamada de permissão Android ao iOS. Autorização nativa, recusa, retomada após interrupção, rota de áudio e silêncio precisam ser verificados no export real. A correção de silêncio digital é compartilhada, mas o fluxo iOS não foi validado em aparelho.

Verificar no Xcode que Info.plist contém a descrição de microfone antes da primeira instalação. Testar permitir, recusar e revogar nos Ajustes; confirmar que o modo sem microfone permite terminar a fase.
