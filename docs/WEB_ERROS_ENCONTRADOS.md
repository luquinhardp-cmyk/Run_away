# Erros encontrados e limites

| Item | Evidência | Situação |
| --- | --- | --- |
| Cópias completas no carregador | 175.183.652 bytes retornados por arrayBuffer no controle | Corrigido: streaming, 34.237.192 bytes no mesmo pacote |
| Download simultâneo de todas as partes | Promise.all seguido de Blob e arrayBuffer | Corrigido: consumo sequencial com contrapressão |
| Silêncio tratado como falha do microfone | RMS abaixo de −79 dB por 6 s revogava consentimento | Corrigido: silêncio com amostras continua válido |
| Navegação calculada antes de concluir o mundo | Bake inicial seguido de outro após decoração/proxies | Corrigido: um bake depois da construção, mantendo atualizações posteriores |
| HUD sem atualização de layout por resize | Layout ligado apenas a Game.updated | Corrigido: sinal resized; safe area também em iOS |
| Recursos de builds antigos dentro do pacote | Log de exportação incluía res://builds/.../index.png e version.json | Corrigido: builds/* excluído dos quatro presets |
| Checkpoint salvo desaparecia do menu ao recarregar | IndexedDB continha checkpoint, mas teste de ida e volta JSON falhava | Corrigido: versão numérica aceita como int ou float, sem aceitar versões fracionárias ou strings |
| Bloqueio ao iniciar a fase | Maior intervalo rAF aproximadamente 20 s nos dois ensaios do carregador | Ainda não resolvido; não atribuir integralmente à navegação |
| Permissão Web aguardando por muito tempo | Timeout de ausência de amostras continua em 6 s | Pendente: distinguir espera, recusa e dispositivo sem fluxo |

Não foi reproduzida perda de contexto WebGL ou falta de memória fatal neste ensaio. Não concluir ausência desses problemas em celulares.
