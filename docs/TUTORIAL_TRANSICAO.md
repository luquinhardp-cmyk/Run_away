# Persistência e entrada sem retorno

Tutorial usa `user://tutorial.json`, ou `user://accounts/<uid>/tutorial.json` quando há uma conta ativa. Seu esquema local é versão 1: stage, step, flags, inventory, cabinet_open, fuse_installed e throwables. Não é enviado ao Firebase. Configurações incluem `tutorial_completed`, salva pela configuração existente.

`Game.in_tutorial` separa os estados: o tempo de fuga não avança, `save_checkpoint` solicita apenas o salvamento da preparação e `finish` não gera resultado de treino. O checkpoint anterior da fase não é sobrescrito durante as lições. O tutorial fica disponível como RETOMAR PREPARAÇÃO enquanto stage=tutorial.

Ao confirmar ENTRAR, a porta articulada abre. Cruzar a área atrás dela registra imediatamente stage=entered e um checkpoint limpo do complexo, sem itens de treino. A pausa durante o fechamento não oferece reiniciar preparação; sair nessa janela também não reabre o tutorial. O jogador permanece na antecâmara enquanto a porta fecha. Quando o mecanismo chega a fechado, a preparação é descarregada. Só então são criados mapa, jogador, HUD e criatura da fase principal.

Configurações e escolha atual de microfone são preservadas. Nenhum item emprestado, fusível instalado, chave de treino ou tempo da preparação é transferido. A fase inicia limpa e grava seu checkpoint normal, respeitando o esquema já aceito pelo Firebase. Não foram acrescentadas chaves de tutorial ao world da nuvem.

Continuar checkpoint, tentar novamente e reiniciar a fase usam diretamente o mapa principal. Não há porta ou ação de retorno ao tutorial. Somente uma escolha explícita de **novo jogo com tutorial** permite repetir a preparação.

Posição exata e trajetórias de objetos soltos não são salvas: retomar reposiciona na estação segura e a lata pode ser recuperada. O progresso local está sujeito às limitações de persistência/limpeza do navegador.
