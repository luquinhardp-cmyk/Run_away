# O Escutador

## Modelo real
Criatura original modelada proceduralmente no Blender: tronco estreito, ombros em alturas diferentes, braços longos, quatro dedos com garras por mão, pernas articuladas, tendões cervicais, placas faciais, mandíbula e conchas auditivas assimétricas. Olhos pequenos e fundos, sem emissão neon. A abertura lateral das conchas diferencia a silhueta de um humano convencional. Não usa roupas, asas, chapéu ou elementos de um personagem existente.

- `assets/models/escutador.glb`: mesh com UVs e skinning, quatro superfícies de material, 29 ossos.
- `assets/models/escutador_low.glb`: geometria reduzida com o mesmo esqueleto e clipes.
- `assets/source/escutador.blend`: fonte editável, imagens empacotadas; `.gdignore` impede importação do `.blend` pela Godot.
- `assets/models/escutador_manifest.json`: contagem efetiva de triângulos, ossos, clipes e proveniência.
- `tools/art/build_escutador.py`: gera modelo, rig, UVs, ações e os dois GLBs.

Escala aproximada de 2,7 m; origem no solo. Usa a cápsula e o NavigationAgent do inimigo existente. O rig de apresentação não desloca o corpo físico. O mesh é anatômico segmentado, com volumes sobrepostos nas articulações; ainda não tem retopologia contínua ou escultura manual final. Isso é uma limitação artística, não uma imagem 2D ou um boneco de caixas.

## Animações incluídas
| Clipe | Duração | Uso |
|---|---|---|
| idle | 3,2 s | pose neutra |
| breathe | 3,6 s | ociosa / respiração |
| walk | 1,2 s | caminhada disponível |
| patrol | 1,4 s | patrulha |
| listen | 1,6 s | percepção auditiva |
| investigate | 1,5 s | aproximação ao estímulo |
| search | 3 s | busca e perda de alvo |
| run / chase | 0,72 s | corrida e perseguição |
| attack | 0,65 s | antecipação de ataque |
| capture | 0,9 s | gesto de captura |
| return | 1,4 s | retorno à patrulha |

Há 12 ações reais no GLB. Alguns pares compartilham a mesma família de movimento; não são 12 interpretações artísticas independentes. O controle visual faz blend, ajusta o ritmo de locomoção à velocidade e mantém escuta/ataque sem loop. A janela de captura do gameplay continua terminando em 0,65 s; somente o início do clipe capture é mostrado antes da derrota.

## Escuta: comportamento central
Audição existente aplica intensidade, distância, paredes, portas e suspeita. Um evento percebido leva a ALERTA. Durante 1,6 s, o corpo para, orienta-se ao estímulo, a cabeça inclina cerca de 33° e as conchas abrem em amplitudes diferentes. Um pequeno estalo espacial reforça o movimento. Depois, a criatura investiga a última posição conhecida.

Eventos repetidos atualizam a memória sem reiniciar continuamente a animação. O microfone não foi reimplementado; o visual recebe somente estados da IA. Ruído alto não garante perseguição automática: visão e lógica de perda/busca continuam ativas. Se já estiver perseguindo visualmente, a criatura não para a cada passo ouvido.

## Armário e captura
Armários têm laterais opacas e lâminas com vãos reais. A câmera foi corrigida para ficar dentro do armário à altura dos olhos, orientada à porta; ao sair, posição e olhar anteriores são restaurados. O microfone permanece sujeito às regras anteriores. Ruído forte ainda pode revelar o esconderijo.

No ataque, os braços e mandíbula usam animação esquelética. O olhar se aproxima suavemente da cabeça do modelo em função da intensidade de sustos; não há teletransporte do inimigo nem overlay com fotografia de monstro.

## Áudio original
`breath`, `creature_step`, `joint`, `listen`, `investigate`, `attack`, `capture` e `chase`. Síntese determinística de ruído filtrado, pulsações e ressonâncias, sem vozes ou amostras externas. Estalos/joint ficam disponíveis para futuros eventos secundários; os demais são associados aos estados e deslocamento. Efeitos emitidos em AudioStreamPlayer3D, com ganho limitado. Ainda não substituem uma sessão de foley profissional.

## Testes
Rig, skinning, UVs, escala, importação dos 12 clipes, variação real dos ossos da cabeça/concha, imobilidade do root, reação a evento auditivo e LOD fazem parte da suíte. Hardware Android e qualidade perceptiva dos movimentos dependem de testes reais adicionais.
