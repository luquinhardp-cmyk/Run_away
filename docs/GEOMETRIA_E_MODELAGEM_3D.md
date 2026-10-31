# Geometria e modelagem 3D — entrega 0.8

Branch `feature/detailed-geometry-models`, sobre a 0.7 (`7253011`). A implementação modifica o projeto Godot existente. As prioridades foram itens próximos, equipamentos usados, portas/móveis, arquitetura e vegetação próxima. Não recria o jogo, não troca o Escutador nem a Sombra Alada.

## Auditoria e classificação

`tests/geometry_audit.tscn` percorre a cena gerada recursivamente: MeshInstance3D, materiais/superfícies/UVs, MultiMesh e colisores. Os inventários completos estão em `geometry_inventory_before.json` e `geometry_inventory_after.json`. O inventário anterior foi conferido em um checkout isolado da 0.7; a cena é construída por scripts e seus materiais/meshes são mesclados em execução, portanto um ArrayMesh não significa automaticamente arte final. Fontes auditadas: `facility.gd`, `facility_art.gd`, `physical_prop.gd`, `mechanism.gd`, `dark_forest.gd`, cenas e GLBs.

| Classe | Elementos anteriores | Decisão |
|---|---|---|
| A — adequados à função | Colisores simples, elos da corrente, esfera de borracha, placas legíveis | Preservar; primitivas úteis não viram complexidade artificial |
| B — necessitavam refinamento | Móveis montados, portas, arquitetura modular, vegetação/terreno, modelos rigados de criaturas | Refinar móveis, portas e ambiente; preservar criaturas funcionais com rig/LOD |
| C — placeholders visíveis | Chave, fusível/lanterna de cilindro simples, cartão, lata, garrafa, ferramenta, dispositivos e gerador de caixa | Trocar por modelos compostos com formas e componentes reconhecíveis |
| D — detalhes ausentes | Encaixe legível de fusível, batentes completos, puxador da gaveta, pilhas decorativas | Acrescentar representação física coerente, sem inventar novas mecânicas |

Os modelos novos são classificados como **B refinados e funcionais**, pendentes de avaliação artística em aparelhos. Não se declara acabamento fotorealista/AAA nem substituição de todas as primitivas do mundo.

## Produção e integração

37 modelos originais e 37 versões leves, criados no Blender 4.5.15 por `tools/art/build_geometry_library.py`. Fonte editável `assets/source/rural_industrial_library.blend`; exports e manifesto em `assets/models/library/`. Cada modelo possui geometria composta, chanfros onde visíveis, normais, UV1 e slots de materiais compartilhados. Pequenos detalhes são textura/normal; nada de subdivisão indiscriminada.

`scripts/world/model_library.gd` carrega/cacheia as cenas e ajusta seus limites ao espaço existente. Troca os visuais mantendo corpos, IDs, massa, gravidade, CCD, som e persistência. Portas conservam o Mesh como âncora no AnimatableBody3D; batentes ficam fixos fora da folha. A gaveta continua com seus painéis/colisores e ganha puxador preso à folha. Fusível instalado é derivado do estado `world.fuse_installed`, sem novo campo de salvamento. A esfera de borracha continua sendo borracha, sem ser disfarçada de pedra.

Materiais: biblioteca PBR anterior reaproveitada; novo `weathered_iron` com albedo/normal/ORM 512 e versão 256, gerado por `generate_machine_pbr.py`. O desgaste de máquinas deixa de usar manchas laranja gigantes. UVs tiled com densidade base de duas repetições por metro, sobreposição intencional de ilhas para materiais repetíveis. O algoritmo limita chanfros em terminais finos; um defeito de UV inicialmente detectado no fusível foi corrigido e revalidado.

## Mudanças no cenário

Gerador aberto com motor, alternador, radiador, instrumentação, tubos e cabos; painel com contatos e porta-fusíveis; chave com aro vazado e dentes; lanterna com lente, cabeçote, ranhuras e botão; garrafa com ombro/gargalo; lata com bordas e anel; ferramenta com boca aberta; caixas com tábuas, reforços e fixadores; cadeira com pernas/encosto; carrinho com bandejas/rodas; bancadas, estantes, armários e tanques.

Arquitetura ganha batentes, vigas/treliças, rodapés, drenos e estrutura exterior. Corrigidos adornos cruzando portas, armários/estantes sobrepostos e telhado visual penetrando o teto. Janela da enfermaria tem abertura real com moldura, barras e vidro quebrado opaco; a altura do peitoril e barras preservam o limite do mapa. Terreno ondula fora das rotas; floresta mantém 736 árvores/arbustos, com árvores próximas modeladas, raízes, galhos assimétricos, copas irregulares e 28 pedras.

## Verificação e limites

229 verificações específicas de geometria/integração; 80 gerais; 41 expansão; 23 horror; 76 ambiente noturno; 47 física: **496 aprovadas, zero falhas**. As verificações de 74 exports incluem carregamento, normais, PBR, UVs não degeneradas, dimensões e redução de triângulos. Integração verifica porta/batente, gaveta, fusível instalado, massas/CCD/som, câmera, janela, floresta e orientação do terreno. A expansão automatizada conclui objetivos e fuga. Não equivale a testes manuais de touchscreen/microfone reais.

Revisão visual reproduzível: `tests/geometry_review.tscn`, Compatibility/Intel UHD, viewport 1280×720. Imagens reais em `review/geometry/`, comparações no subdiretório `before`; detalhes de itens usam uma mesa de inspeção com luz neutra, escala real e FOV 40, separada da iluminação do jogo. A imagem de raízes usa câmera de inspeção além da cerca; não representa uma nova área acessível. Contadores em `metrics.json` não são FPS Android.

Limitações: detalhes procedurais estilizados, colisores simplificados/conservadores, vidro opaco e quebrado sem simulação de estilhaços, terreno decorativo sem criar floresta explorável, pilhas decorativas sem novo inventário, rodas/painéis de máquinas sem nova simulação mecânica. Validação física de Android, desempenho sustentado, calor, bateria, áudio/microfone e ergonomia continuam pendentes. Não foram alterados regras/schema de Firebase, pontuação ou objetivos.

Guias: [padrão visual](PADRAO_VISUAL_OBJETOS.md), [arquitetura](ARQUITETURA_CENARIOS.md), [biblioteca](BIBLIOTECA_MODELOS_3D.md), [otimização](OTIMIZACAO_GEOMETRIA_ANDROID.md).
