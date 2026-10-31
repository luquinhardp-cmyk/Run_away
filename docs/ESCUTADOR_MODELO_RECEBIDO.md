# Integração do GLB recebido — prévia técnica

**A integração funcional está implementada. O grau de realismo extremo solicitado ainda não foi atingido. Esta entrega é um refinamento procedural integrado, não um personagem final de produção.** As pendências artísticas estão discriminadas abaixo, sem tratar a presença de rig e texturas como prova de fotorealismo.

## Auditoria e origem

Importado realmente no Blender 4.5.15 a partir do ZIP fornecido pelo usuário. O GLB original tem 130 malhas, 21.684 triângulos, cores de vértice, zero armatures, zero animações e zero UVs. Seu SHA-256 é `31cd026684522188cee228d5298e757d785513e3478317c6b8a96ddb26dc9694`. Cópia intacta, README e gerador fornecido estão em `assets/source/received_escutador/`. O gerador do ZIP não foi executado. As instruções internas do README foram tratadas como contexto do anexo; a solicitação do usuário orientou o trabalho.

O modelo anterior do jogo continua no histórico Git e em `assets/models/escutador_v2*.glb`. A nova apresentação usa `escutador_received.glb` e `escutador_received_low.glb`, sem substituir a criatura alada. O arquivo editável principal é `assets/source/received_escutador/escutador_refined.blend`.

## Trabalho efetivamente realizado no Blender

- Importação da malha recebida, preservando a origem verificável; escala 0,74 e ajuste da origem para o piso/altura do mundo existente.
- Corpo unificado por voxel remesh e suavização; contorno de cintura, tendões cervicais, sulcos e irregularidades geométricas. Não é uma retopologia manual com edge loops anatômicos.
- Reconstrução da cabeça: removidos focinho esférico, olhos esféricos e maxilar plano. Criados crânio alongado, arco zigomático, ponte nasal, recessos orbitais oblíquos, cavidade oral e arco mandibular articulado. As últimas órbitas usam cavidades geométricas, sem globos ovais brilhantes inseridos.
- Membranas auditivas côncavas, com espessura e bordas irregulares, reduzidas e assimétricas após revisão visual. Garras curvadas em segmentos, dentição de comprimentos diferentes e rugas/sulco facial geométrico.
- UVs reais para materiais repetíveis com densidade aproximada de 2,5 repetições por metro. Sobreposição é intencional; não existe um atlas único pintado à mão com identidade específica por região corporal.
- Armature real de 29 ossos, grupos de vértice e pesos. O exportador limita/normaliza a quatro influências na malha reduzida. Um mesh de apresentação com três superfícies de material.
- 28.068 triângulos no principal, 12.348 no reduzido. 23 ações glTF: idle, breathe, walk, patrol, listen, investigate, search, run, chase, attack, capture, return, head_tilt, hide_search, lost e oito capturas contextuais. As oito capturas possuem poses esqueléticas diferentes.
- Marcha em posição fixa com solução analítica de pernas por IK, elevação do pé em balanço, contraposição dos braços, respiração discreta e escuta com cabeça/pavilhões articulados. Os controles foram amostrados em keyframes; não existe dependência de constraints Blender em runtime. Não foi usado motion capture.

Scripts reproduzíveis: `tools/art/audit_received_escutador.py`, `build_received_escutador.py`, `animate_received_escutador.py` `export_received_escutador.py` e `reanimate_received_escutador.py`. O último reexporta a cena salva sem reconstruir a anatomia. A cena Blender contém os materiais completos; os GLBs preservam nomes de materiais sem duplicar imagens embutidas, e o Godot aplica os recursos compartilhados.

## Materiais

Base de cor de pele envelhecida/deteriorada gerada com a habilidade [imagegen](C:/Users/DANF/.codex/skills/.system/imagegen/SKILL.md) e preservada no projeto. Normal de microdetalhe e rugosidade foram gerados matematicamente no Blender; **não são mapas escaneados nem bake de escultura de alta resolução**. ORM: vermelho neutro 1, verde rugosidade variável e azul metálico 0; não foi alegado AO anatômico baked.

Resoluções 1024 e 512; mipmaps, filtragem linear/anisotrópica conforme perfil. Pele e cartilagem reutilizam mapas com tintas/roughness próprias; queratina usa material separado. As órbitas são recessos da malha, sem inserts esféricos; a camada de material escuro de cavidade permanece disponível no controlador, mas não é usada nas três superfícies finais. O perfil baixo não carrega o normal de pele. Os mapas e a coloração ainda precisam de revisão artística, especialmente para reduzir repetição e obter pele com resposta física mais convincente em todas as luzes.

## Integração preservada

Única alteração do runtime da criatura: `scripts/enemy/escutador_visual.gd`, para carregar os novos GLBs e aplicar materiais compartilhados. Estados, sensores, memória, audição do microfone, limites de ataque, navegação, sons e persistência continuam nos sistemas existentes. Mantidos CapsuleShape3D altura 2,4/radius 0,32, NavigationAgent radius 0,35 e máscaras de colisão. A apresentação não move o CharacterBody.

Nomes de ossos e clips preservam o contrato do controlador existente com AnimationPlayer. Não foi introduzido AnimationTree nem uma segunda IA. Cabeça continua fornecendo o ponto de foco ao jumpscare; o zoom, áudio forte e opções de acessibilidade permanecem. A captura só ocorre após o contato validado pelo jogo.

## Android e validação

Dois exports geométricos, materiais reutilizados, um esqueleto, três superfícies e textura reduzida no baixo. Quantidades finais estão em `assets/models/escutador_received_manifest.json`. O LOD é escolhido pela qualidade; mantida a distância visual existente de 42 m e os LODs de malha gerados pelo importador Godot. A física e os sentidos não são reduzidos por perfil.

Suíte específica: 84 verificações aprovadas, cobrindo carregamento dos dois LODs, 29 ossos, 23 clips, pesos normalizados, materiais, mipmaps, escala, movimento esquelético limitado, cabeça/escuta, pé plantado, raiz estável, capturas distintas e orçamento de triângulos. Regressão: 80 gerais, 41 expansão, 29 horror, 47 física, 76 noite, 229 geometria e 20 gráficos — **606 verificações aprovadas no total**. O teste de expansão conclui os objetivos e a fuga. O teste de microfone utiliza sinais/eventos simulados, não captação acústica de aparelho físico.

Imagens reais em `review/escutador_received/`: entrada original, frontal, rosto, costas, escuta, perseguição e captura dentro da fase. Entrada foi renderizada em Workbench/cores de vértice; saída no Godot Compatibility/PBR com iluminação de inspeção, portanto não constitui comparação fotométrica calibrada. Screenshots verificam a apresentação, sem certificar qualidade artística final ou FPS Android.

## Pendências exatas

1. **Escultura anatômica final:** refinar planos faciais, músculos, clavículas, junções de ombro/cotovelo/joelho, pele pendente e estruturas auditivas. A aparência ainda contém simplificações procedurais; não foi eliminada com garantia toda leitura estilizada/de boneco.
2. **Retopologia manual de deformação:** edge loops para ombros, cotovelos, joelhos, boca e dedos. Remesh/decimação não substituem essa etapa; poses extremas ainda podem mostrar vincos duros e perda de volume.
3. **UV/texture painting final:** atlas anatômico, cicatrizes e rugas específicas por região, calibração de cor/roughness e bake high-to-low de normal/AO/cavity. A base gerada não equivale a captura física de pele.
4. **Polimento de animação:** revisão quadro a quadro de apoio/deslizamento de pés na velocidade real da IA, distribuição de peso, ações secundárias, contatos de mãos e capturas. IK/keyframes exportados são funcionais, sem certificar movimento humano fotorealista.
5. **Aparelhos reais:** FPS sustentado, memória, aquecimento, bateria, microfone, multitoque, escala/visibilidade e instalação de atualização mantendo dados. Nenhum Android físico estava conectado.

O material entregue permite continuar essas etapas no `.blend` real. A prévia não deve ser anunciada como personagem hiperrealista finalizado.
