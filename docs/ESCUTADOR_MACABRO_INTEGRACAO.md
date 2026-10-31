# Substituição pelo Escutador_Monstro_3D.glb

O visual da criatura terrestre agora usa o GLB enviado pelo usuário. A imagem fornecida orienta a aparência; ela não é uma textura do modelo e o arquivo 3D não contém o mesmo nível de detalhe fotográfico.

## Trabalho executado

O arquivo original contém 358 peças, cores de vértices e nenhum rig ou animação. No Blender foram criados um esqueleto compatível de 29 ossos, pesos normalizados, união por voxel da pele do corpo e transições suavizadas. Essa união reduz aberturas entre os segmentos durante a deformação. As cores foram transferidas e seus atributos normalizados antes da junção; dentes, boca, orelhas e garras mantêm pigmentação própria.

São 23 clips exportados: respiração, espera, caminhada, patrulha, escuta com inclinação da cabeça/orelhas, investigação, procura, corrida, perseguição, ataque, retorno, busca em esconderijo, perda do alvo e nove clips de captura (um genérico e oito variantes). As pernas usam solução analítica de apoio, com animação no lugar e velocidade ajustada ao deslocamento físico. As mudanças de estado usam blends; uma parada de navegação passa para respiração com histerese. A locomoção não interrompe uma captura.

Materiais PBR preservam as cores do arquivo, rugosidade por tecido e normal de pele reaproveitada do projeto. Não foi aplicada a imagem inteira ao corpo nem apresentado um material escaneado como criado. O perfil baixo desativa normal maps. Há um mesh animado com quatro superfícies, aproximadamente 26.840 triângulos no perfil normal e 14.756 no baixo.

## Sistemas preservados

A troca ocorre em `scripts/enemy/escutador_visual.gd`. O CharacterBody, cápsula, NavigationAgent, estados e percepção da IA, NoiseBus, microfone, portas, investigação de esconderijos, objetivos e salvamento continuam nos sistemas existentes. A sequência de captura mantém som, aproximação da câmera, zoom e suas configurações de intensidade. As animações não deslocam a raiz física.

Arquivos novos: `assets/models/escutador_macabre{,_low}.glb`, manifesto JSON, `assets/source/macabre_escutador/escutador_macabre.blend`, original preservado, `tools/art/integrate_macabre_escutador.py`, `tests/macabre_runner.*` e `tests/macabre_review.*`. Os presets excluem os antigos GLBs da criatura recebida dos pacotes de distribuição, mantendo-os no projeto como histórico.

## Verificação e entrega

[Resultados e logs](review/escutador_macabre/validation.json). [Frente](review/escutador_macabre/macabre_front.png), [rosto](review/escutador_macabre/macabre_face.png), [escuta](review/escutador_macabre/macabre_listen.png), [perseguição](review/escutador_macabre/macabre_chase.png). Capturas geradas pela renderização Compatibility no Godot.

Foram aprovadas 328 verificações nativas em seis suítes: rig/animações (82), modelo/material/estados (55), terror/capturas (29), IA/objetivos (41), regressão principal (80) e tutorial (41). No Chromium, a suíte de terror completou outras 29 verificações sem erros durante a execução. Ao encerrar a engine Web, houve um aviso de alocação WorkerThreadPool; o log bruto e a separação entre execução e encerramento estão em `review/escutador_macabre/chromium-qa.json`. Essa pendência não foi declarada resolvida.

Pacote local: `builds/macabre/ecos-macabre-web.zip`; tamanho e SHA-256 em `review/escutador_macabre/artifact.json`. O arquivo está marcado como não publicado.

O arquivo Blender permite continuar a edição real. O processo é reproduzível pelo script de integração. As animações são keyframes com IK analítico, sem captura de movimento. A malha usa remesh e redução automática, sem retopologia manual de produção; alguns componentes e detalhes geométricos simplificados da base permanecem perceptíveis de perto. Não equivale à escultura realista da imagem.

Não foram medidos FPS, temperatura, deformação sob todos os ângulos ou microfone em aparelhos físicos. A exportação Web local e os testes automatizados não substituem esses ensaios. Não houve publicação, troca de links, novo APK ou alteração do certificado Android nesta etapa.
