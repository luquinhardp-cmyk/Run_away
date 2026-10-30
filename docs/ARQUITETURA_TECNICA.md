# Arquitetura técnica

## Versão e composição
Godot 4.7.2 stable / GDScript / Mobile Vulkan. Projeto organizado em cenas independentes; geometria e interface são criadas por scripts para permanecerem autocontidas e editáveis. O boot instancia menu → fase → jogador → criatura → HUD. A navegação é gerada sincronamente na carga, antes das portas móveis. Aguardamos a primeira sincronização do NavigationServer antes de mover a criatura.

## Módulos
| Arquivo | Responsabilidade |
|---|---|
| scripts/systems/main.gd | Fluxo de telas, consentimento, cenas e encerramento |
| scripts/systems/game.gd | Inventário, objetivos, configurações e checkpoint |
| scripts/systems/facility.gd | Planta, colisões, navegação, materiais, luzes, eventos |
| scripts/player/player.gd | Movimento, câmera, raycast de interação, esconderijo |
| scripts/player/hud.gd | Multitouch, botões, objetivos, feedback |
| scripts/enemy/creature.gd | Máquina de estados, visão, audição, navegação, animação |
| scripts/interactions/interactable.gd | Ações dos elementos da fase |
| scripts/audio/noise.gd | Contrato de ruído e atenuação/oclusão |
| scripts/audio/microphone.gd | Consentimento, permissões, captura e intensidade |
| scripts/audio/sound.gd | Efeitos 3D e volumes dos buses |

Autoload `NoiseBus` evita conflito com a classe nativa `Noise` da Godot. Ruídos de gameplay são eventos, independentes da reprodução sonora e do volume escolhido. Reduzir o volume dos efeitos não engana a IA.

## Camadas físicas
1 ambiente/portas, 2 jogador, 4 criatura, 8 interação. O raycast do jogador considera ambiente e interação, impedindo coleta através de parede. A visão da criatura considera ambiente e jogador. Navegação inclui colisões estáticas de ambiente; portas são abertas pela criatura ao bloquear sua aproximação. Mobiliário sólido é incluído no bake; objetos de interação pequenos não bloqueiam fisicamente o trajeto nesta base.

## Salvamento
`user://settings.cfg` via ConfigFile; `user://checkpoint.json` com versão de esquema 1 e gravação em temporário seguida de rename. Salva cópias do inventário e estado de portas para impedir alias com a sessão. Retomada segura na enfermaria. Não salva posição ou estado da criatura. Consentimento de microfone nunca é persistido.

## Performance
Geometria simples, biblioteca PBR 512²/256², colisões em caixas/cápsulas, luzes locais sem sombras (lanterna com sombra apenas no perfil alto), percepção visual a ~5,5 Hz. Baixa: escala 3D 65%, limite 30 FPS. Média: 85%, limite 60. Alta: 100%, limite 60 e sombra na lanterna. As luzes são limitadas ao alcance próximo; não há LOD ou oclusão baked nesta fase compacta. Fazer bake offline de navmesh e lightmaps é melhoria futura para diminuir carga e custo em mobile.

## Fontes técnicas
- [Captura de amostras no bus](https://docs.godotengine.org/en/stable/classes/class_audioeffectcapture.html)
- [Entrada de microfone](https://docs.godotengine.org/en/stable/classes/class_audiostreammicrophone.html)
- [Exportação Android](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)

## Camada de arte 0.2

`horror_art.gd`: PBRs, perfis e união espacial de meshes. `facility_art.gd`: detalhes separados da lógica de objetivos. `escutador_visual.gd`: GLB, Skeleton3D e AnimationPlayer, sem movimentar o CharacterBody. `menu_stage.gd`: tableau 3D com ambiente ativado apenas no menu. O microfone e o barramento de ruídos não foram alterados.
