# Direção de arte — ECOS 0.2

## Identidade
Instalação de drenagem e manutenção rural abandonada. Concreto úmido, ferrugem, madeira envelhecida, vegetação morta e anatomia predatória. As referências fornecidas orientam atmosfera, composição, isolamento e contraste; nenhum personagem, veículo, figurino, imagem ou asset dessas obras foi incorporado.

| Uso | Cor |
|---|---|
| Fundo / sombra | #0B0D0C / #191D1B |
| Concreto | #444641 |
| Ferrugem / madeira | #71432F / #3E3027 |
| Vegetação | #354438 |
| Luz antiga | #B19A64 |
| Resíduo orgânico | #592A29 |
| Pele / cartilagem | #575247 / #49352E |

Os albedos mantêm valores intermediários para responder à luz, em vez de escurecer todas as texturas até preto. A lanterna revela detalhes próximos; luzes quentes recortam corredores e a criatura. Névoa simples, sem volumetria, fecha a visibilidade externa. Quedas isoladas de luminosidade substituem a antiga oscilação rápida; não há flashes.

## Ambientes implementados
- Corredor original: materiais PBR, flanges, tubos cilíndricos, válvulas, suportes, cabos modelados, marcas de garras, umidade e detritos nas bordas.
- Enfermaria: cama abandonada, colchão/tecido e caixilho opaco quebrado.
- Depósito: estantes, caixas, cobertura de tecido e armário com frestas reais.
- Oficina/manutenção: prensa, ferramentas, corrente e bancada; fusível preservado.
- Segurança: monitores analógicos desligados e console; cartão preservado.
- Energia: tanques e tubulação; gerador e checkpoint preservados.
- Pátio externo: terreno de terra, sulcos, vegetação seca em MultiMesh, cerca, portão fechado, poste, fachada e árvores além da área navegável.
- Subsolo: rampa de acesso pela energia, sala rebaixada, concreto úmido, poças e áudio de gotejamento.
- Fuga: entulho lateral, luz fria discreta e faixa central livre.

O corredor e as cinco salas originais mantêm as mesmas coordenadas e objetivos. Duas aberturas e os anexos ampliam a planta; testes verificam caminhos navegáveis até ambos. Detalhes decorativos não acrescentam colisões invisíveis no percurso. Os anexos têm piso, paredes e limites físicos próprios.

## Menu e interface
O menu usa um cenário 3D original, câmera com oscilação muito discreta e áudio de vento. Tipografia padrão legível, cores envelhecidas e overlay de contraste. HUD preserva ações, posição dos controles e indicador de microfone; a paleta passou a carvão/ocre. A captura usa o modelo 3D e aproximação suave do olhar, sem imagem estática na tela.

## Ferramentas e arquivos
Godot 4.7.2 stable; Blender 4.5.15 LTS portátil; Python/NumPy para mapas e áudio. Sem serviços de geração 3D externos ou modelos baixados. `scripts/systems/facility_art.gd` contém os detalhes; `horror_art.gd` gerencia os PBRs e lotes; `menu_stage.gd` contém o quadro do menu. Fontes reproduzíveis em `tools/art/`.

## Revisão e limites
Capturas reais da Godot em `docs/review/`, incluindo corredor, depósito, oficina, energia, subsolo, exterior, criatura e armário. Os assets são uma primeira versão artística procedural de baixa poligonagem. Não são escultura fotorrealista, materiais fotografados, animação de mocap ou arte final de produção. Ainda faltam polimento manual de anatomia, mais variação de mobiliário e playtest de legibilidade em telas pequenas.

Origem/licenças: recursos visuais e sonoros novos são originais deste projeto; não há licença de terceiros aplicada a eles. O titular do projeto pode usá-los e modificá-los; não foi escolhida uma licença pública de redistribuição do projeto. Blender e Godot são ferramentas externas, não assets copiados. Os arquivos de referência não são distribuídos no jogo.
