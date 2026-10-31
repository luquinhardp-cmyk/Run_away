# Biblioteca de modelos 3D

37 modelos originais criados no Blender, cada um com GLB normal e leve. Arquivos: `assets/models/library/<id>.glb` e `<id>_low.glb`. Fonte: `assets/source/rural_industrial_library.blend`; gerador: `tools/art/build_geometry_library.py`. O manifesto JSON guarda materiais, dimensoes, componentes e classificacao.

As classificacoes B/C/D abaixo descrevem a representacao anterior. Todos os modelos novos sao B refinados/funcionais, sujeitos a avaliacao artistica e de hardware. A esfera de borracha, os elos e os colisores apropriados foram preservados.

| Modelo | Classe anterior | Triangulos normal | Triangulos leve | Materiais |
|---|---|---:|---:|---|
| `key` | C | 1116 | 612 | brushed_metal |
| `fuse` | C | 1432 | 786 | torn_fabric, brushed_metal, aged_plastic |
| `flashlight` | C | 3896 | 2142 | worn_rubber, aged_plastic, brushed_metal, dirty_glass, rusted_iron |
| `security_card` | C | 264 | 144 | aged_plastic, brushed_metal, worn_rubber, torn_fabric |
| `wrench` | C | 1008 | 554 | brushed_metal |
| `bottle` | C | 580 | 318 | dirty_glass, brushed_metal, torn_fabric |
| `can` | C | 1436 | 788 | industrial_sheet, brushed_metal |
| `crate` | B | 2968 | 1632 | rotten_wood, damp_wood, brushed_metal |
| `bucket` | C | 760 | 418 | wet_steel, brushed_metal, rusted_iron, worn_rubber |
| `chair` | B | 1632 | 896 | old_upholstery, rusted_iron, brushed_metal |
| `trolley` | B | 1680 | 924 | wet_steel, rusted_iron, brushed_metal, worn_rubber |
| `workbench` | B | 1484 | 816 | damp_wood, rotten_wood, rusted_iron, brushed_metal |
| `shelf` | B | 1644 | 904 | rusted_iron, brushed_metal, industrial_sheet |
| `locker` | B | 1972 | 1084 | industrial_sheet, rusted_iron, brushed_metal |
| `diesel_generator` | C | 8080 | 4444 | rusted_iron, wet_steel, brushed_metal, industrial_sheet, aged_plastic, dirty_glass, torn_fabric, worn_rubber |
| `fuse_panel` | C | 2412 | 1326 | industrial_sheet, rusted_iron, aged_plastic, torn_fabric, brushed_metal, worn_rubber |
| `door_steel` | B | 2308 | 1268 | industrial_sheet, rusted_iron, worn_rubber, brushed_metal |
| `door_wood` | B | 2308 | 1268 | rotten_wood, rusted_iron, brushed_metal, worn_rubber |
| `door_exit` | B | 2968 | 1632 | industrial_sheet, rusted_iron, worn_rubber, brushed_metal |
| `radio` | C | 1676 | 920 | aged_plastic, worn_rubber, brushed_metal, dirty_glass, rusted_iron |
| `alarm` | C | 876 | 480 | rusted_iron, industrial_sheet, worn_rubber, brushed_metal |
| `battery` | D | 288 | 158 | aged_plastic, brushed_metal |
| `rock` | C | 80 | 44 | aged_concrete |
| `tank` | B | 1772 | 974 | industrial_sheet, rusted_iron, brushed_metal |
| `motor` | C | 3920 | 2156 | wet_steel, industrial_sheet, brushed_metal, rusted_iron, aged_plastic |
| `workshop_press` | B | 1188 | 652 | rusted_iron, industrial_sheet, brushed_metal, worn_rubber |
| `broken_window` | B | 762 | 418 | rotten_wood, damp_wood, rusted_iron, dirty_glass |
| `drain` | B | 1308 | 718 | rusted_iron, worn_rubber, brushed_metal |
| `roof_truss` | B | 1868 | 1026 | rotten_wood, rusted_iron |
| `pallet` | B | 1080 | 594 | damp_wood, rotten_wood |
| `tree_dead` | B | 9324 | 5128 | rotten_wood |
| `tree_broadleaf` | B | 9764 | 5370 | rotten_wood, moss |
| `tree_pine` | B | 9429 | 5185 | rotten_wood, moss |
| `crt_monitor` | C | 1384 | 760 | aged_plastic, dirty_glass, worn_rubber, brushed_metal, rusted_iron |
| `door_frame` | D | 660 | 362 | rusted_iron, industrial_sheet, brushed_metal |
| `drawer_handle` | D | 364 | 200 | rusted_iron, brushed_metal |
| `mechanical_part` | C | 2012 | 1106 | rusted_iron, brushed_metal |

## Integracao

- Interacoes: key/fuse/flashlight/security_card, diesel_generator/fuse_panel, radio/alarm, door_steel/door_wood/door_exit, locker/workbench, mechanical_part.
- Fisica: can, bottle, wrench, crate, bucket, chair e trolley. As variantes de caixas compartilham geometria e respeitam o tamanho do perfil. rock aparece na decoracao, sem alterar a esfera de borracha.
- Arquitetura: door_frame, drawer_handle, broken_window, drain e roof_truss.
- Salas: shelf, pallet, battery, crt_monitor, tank, motor e workshop_press.
- Floresta: tree_dead/tree_broadleaf/tree_pine nos lotes proximos; vegetacao intermediaria distante simplificada; rock em 28 instancias mescladas.

UV1 tiled com densidade base de 2 repeticoes por metro; sem atlas esticado. Normais e UVs dos 74 exports sao verificados em tests/geometry_runner.tscn. Slots rusted_iron dos modelos recebem weathered_iron no Godot. Materiais PBR sao compartilhados e atualizados pelo perfil grafico.

Colisores sao os corpos simplificados anteriores, com excecao da abertura real de janela e barras correspondentes. Pe?as de acabamento nao recebem corpos individuais. O runtime usa o slot do modelo dentro do corpo existente; nao troca IDs de inventario/checkpoint.

Gerar novamente: `blender --background --python tools/art/build_geometry_library.py`; depois importar o projeto na Godot. Os arquivos fonte e exports preservam recursos editaveis, nao so malhas montadas em memoria.
