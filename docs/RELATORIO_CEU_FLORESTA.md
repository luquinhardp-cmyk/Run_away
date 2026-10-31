# Entrega 0.7 — céu, floresta e Sombra Alada

Implementação no projeto existente, branch `feature/blood-moon-dark-forest`. Não substitui o Escutador nem cria outra IA de perseguição. A auditoria antecedeu as alterações. Recursos novos são originais, procedurais e simplificados; as referências orientam clima/composição, sem copiar personagens.

Concluído: Sky permanente com lua distante craterada, estrelas e halo; floresta 360° em quatro camadas com 736 árvores/arbustos, vento e limites vegetados; névoa leve e iluminação externa reduzida; modelo alado com rig de 11 ossos, dois LODs e seis animações; sete padrões contextuais raros com áudio espacial original, passagem muda e grito após desaparecer; integração com câmera/teto, captura, perseguição, pausa e HorrorDirector; três perfis gráficos; documentação e revisão visual.

Arquivos existentes alterados: `scripts/systems/facility.gd` adiciona o subsistema; `facility_art.gd` reduz duas luzes externas e remove loop redundante; `game.gd` mantém último padrão da sessão; `main.gd` identifica versão; `export_presets.cfg` usa diretório isolado `builds/forest` e versão 0.7/code7. Novos módulos em `scripts/environment`, configurações em `resources/environment`, shaders em `shaders`, modelos/textura/sons em `assets`, geradores em `tools/art`. Nenhuma alteração em regras de Firebase, IA terrestre, controles, objetivos ou schema de checkpoint.

Validação: importação Godot 4.7.2 sem erros, 76 testes de ambiente + 79 gerais + 41 expansão + 23 horror + 47 física = **266 aprovados, zero falhas**. A expansão automatizada termina em fuga com objetivos integrados; a regressão verifica checkpoint e retorno ao menu. Capturas reais Compatibility/Intel UHD em `review/night`: lua, floresta com lanterna, Sombra cruzando disco e perfis baixo/médio/alto. Os resultados não representam FPS de Android físico.

Guias técnicos: [céu](CEU_LUA_DE_SANGUE.md), [floresta](FLORESTA_DENSA.md), [modelo](CRIATURA_ALADA.md), [eventos](EVENTO_VOO_CRIATURA.md), [áudio](AUDIO_AMBIENTAL_FLORESTA.md), [otimização/testes/pendências](OTIMIZACAO_AMBIENTE_ANDROID.md).

Limitações: acabamento procedural de silhuetas; sem pouso/caça aérea, partículas individuais, volumetria ou floresta explorável além das cercas. Histórico/cooldown aéreo não persistem ao fechar o jogo. A travessia diante da lua depende de olhar para sua direção e respeita o contexto; nenhum evento é garantido na janela. Hardware Android, equilíbrio perceptivo de áudio e brilho em telas distintas permanecem pendentes.
