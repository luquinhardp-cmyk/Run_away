# Otimização gráfica e validação — 0.2

## Perfis implementados
| Perfil | Texturas PBR | Criatura | Escala 3D | Sombras |
|---|---|---|---|---|
| Baixo | 256², normal/AO desativados | GLB reduzido, mesmo rig | 65% | nenhuma luz com sombra |
| Médio | 512², normal/AO ativos | GLB principal | 85% | nenhuma luz com sombra |
| Alto | 512², normal/AO ativos | GLB principal | 100% | sombra na lanterna |

Vegetação: 80 / 160 / 220 instâncias visíveis. Luzes locais têm alcance limitado e nenhuma simulação de iluminação global. Número de FPS configurado é limite (30 no baixo, 60 nos demais), **não uma medição**. A intenção é 30 FPS no aparelho modesto de referência, ainda não selecionado/testado.

## Custo controlado
Detalhes estáticos são unidos por material e região espacial de 8 m. Isso reduz draw calls em relação a centenas de primitivas soltas, preserva AABBs úteis para culling e evita que um único mesh do prédio escolha luzes incorretas para todas as salas. Colisões originais ficam separadas. Lâminas e peças de cada armário também são unidas, mantendo o objeto interativo e os vãos.

Vegetação usa MultiMesh; cabos, correntes e água são geometria estática. Normais de pele concentram detalhes sem subdivisão pesada. Não há física de tecido, corrente ou músculos. A criatura tem somente quatro superfícies de material e é ocultada além de 42 m. O LOD troca pelo perfil; ainda não há transição de LOD por distância. Não foi implementado occlusion culling baked nem lightmap, e o bake de navegação continua acontecendo na carga.

## Observado nesta máquina
Renderização Mobile/Vulkan na Intel UHD Graphics, viewport 1280×720, capturas sem HUD em `docs/review/`. `render_metrics.json` contém draw calls, primitivas e objetos reportados pela Godot para cada vista. As métricas são amostras de captura e variam por renderer/perfil/câmera; não são benchmark de celular. As capturas usam a lanterna acesa para inspeção dos materiais.

## Validação executada
- Importação dos PNGs comprimidos, GLBs e recursos sem erros críticos.
- **69 verificações automatizadas passaram**: as 43 anteriores, mais validação de arte, cabeça/concha em movimento, rig/UV/skin/escala, LOD, dez PBRs e navegação dos dois anexos.
- Dez vistas renderizadas: menu, corredor, depósito, oficina, energia, subsolo, pátio, corpo inteiro, escuta e visão do armário.
- O sistema de captura/análise do microfone permaneceu inalterado; suas funções RMS, gate e integração por eventos continuam cobertas pela suíte.
- `adb devices` não encontrou aparelho conectado. FPS, aquecimento, microfone e multitouch físicos Android **não foram medidos nesta revisão**.

## Próxima medição em Android
Usar o mesmo percurso por 15 minutos nos três perfis. Registrar modelo/SoC/GPU/RAM/Android, resolução, tempo de carga/bake, frame time p50/p95/p99, draw calls, memória e temperatura. Repetir com lanterna, perseguição e microfone. Medir também o Web export separadamente: usa Compatibility/WebGL2 e tem custo diferente do APK Mobile/Vulkan.

## Pendências artísticas/técnicas
Retopologia e pintura manual da criatura; polimento de caminhada/captura; mais variação de danos sem repetição; reflexão de poças se o orçamento permitir; iluminação pré-calculada; bake offline de navmesh; playtest das frestas em telas pequenas. Não se declara arte AAA nem desempenho mobile certificado.

### Amostras desta captura

Foram reportadas 8–218 draw calls por vista, incluindo menu e exterior, e até 21216 primitivas. São contadores instantâneos, sem afirmação de 30/60 FPS. O exterior e a visão longa do corredor merecem prioridade no profiling de celular.
