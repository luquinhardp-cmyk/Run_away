# Física de objetos — ECOS 0.6

Branch `feature/physical-world-materials`, continuação direta da 0.5. Inventário anterior: `INVENTARIO_FISICA_before.json`; posterior: `INVENTARIO_FISICA_after.json`. A cena é majoritariamente gerada por scripts, então o levantamento instancia a fase completa e percorre malhas, corpos, formas e juntas. Há identificador/caminho, cena, script, tipo, materiais/texturas, camada/forma, gravidade, movimento, interação, massa de gameplay, sons e custo por registro. Caminhos automáticos de objetos não nomeados são identificadores daquela execução, não IDs persistentes.

## Classificação

| Categoria | Objetos | Solução |
|---|---|---|
| A | paredes, piso, teto, rampa, bancadas, tubulações, máquinas ancoradas | StaticBody3D; decoração fina agrupada sem solver |
| B | lata, garrafas, ferramenta, caixa pequena, balde, borracha, caixa frágil | RigidBody3D nativo, CCD, formas simples, sleeping |
| C | cadeira, caixa de carga, carrinho | massas maiores, empurrar e arrastar horizontalmente |
| D | armários, gerador, prensa, mesas fixas | estáticos; não levantáveis pelo jogador |
| E | portas, gaveta, corrente suspensa | AnimatableBody3D e movimento limitado |
| F | lanterna, fusível, cartão, chave, rádio, alarme, documentos e peças de inventário | lógica e IDs originais preservados |

## Objetos dinâmicos e massas

| Perfil | Massa (kg de gameplay) | Permissões |
|---|---:|---|
| lata | 0,2 | empurrar, segurar, arremessar, rolar |
| garrafa | 0,55 | segurar, arremessar, tombar; quebra acima de 5,5 m/s de impacto |
| ferramenta | 1,2 | segurar, arremessar |
| caixa pequena | 2,5 | segurar, arremessar |
| caixa de carga | 12 | empurrar, arrastar no chão |
| cadeira | 6 | empurrar, tombar, arrastar |
| carrinho | 18 | empurrar e arrastar |
| balde | 1 | segurar, arremessar, tombar |
| borracha | 0,45 | segurar, arremessar, quicar |
| caixa frágil | 1,5 | segurar, arremessar; quebra acima de 6 m/s |

Valores calibrados para o controlador com limite de levantamento de 3 kg, arrasto de até 20 kg e forças máximas de 45/95 N. São aproximações de gameplay, não medidas industriais. Armários e gerador não têm massa simulada; a estimativa do inventário é apenas classificação de peso. O carrinho usa estrutura composta e atrito, sem suspensão ou rodas fisicamente articuladas.

`scripts/physics/object_profile.gd` e `resources/physics/objects/*.tres` configuram categoria, forma, dimensões, massa, superfície, PBR e permissões. `physical_prop.gd` cuida da simulação, impacto, quebra e snapshot. `world_physics.gd` instancia 12 corpos autorais: lata, duas garrafas, duas ferramentas (incluindo gaveta), duas caixas, cadeira, carrinho, balde, esfera e caixa frágil. Estruturas não foram convertidas indiscriminadamente.

## Colisões e gravidade

Escala em metros; gravidade nativa 9,8 m/s² compartilhada pelos personagens via get_gravity e pelos rigid bodies. Não há aplicação manual de gravidade nos RigidBody3D. Máscaras de bits: 1 mundo/mecanismos, 2 jogador, 4 criatura, 8 interação, 16 objetos físicos e 32 proxies exclusivos do bake de navegação. Personagens colidem com 16 e aplicam impulsos limitados; ignoram 32. Objetos rápidos usam continuous_cd e até oito contatos reportados. Proxies de móveis ancorados fora da NavigationRegion alimentam o bake sem duplicar colisão de gameplay; corpos dinâmicos continuam fora do bake.

Formas: caixas/cilindros/esfera e composição de assento, encosto e pernas para cadeira. Há hulls fixos novos para cama, prensa e carrinho decorativo ancorado. Gerador, armários, dispositivos e pickups sólidos ganharam colisão de mundo. Objetos de inventário soltos foram apoiados no piso; chave recebeu prateleira; consoles foram realinhados às bancadas. Etiquetas, cabos finos, manchas, folhas e pequenos detritos visuais não recebem colisões individuais.

## Estado e quebra

`world.physics` guarda transformações arredondadas a centímetro/centirradiano e flag broken por ID; gaveta guarda open. Snapshot ocorre a cada dois segundos e imediatamente antes do checkpoint. Não serializa velocidades nem restrições transitórias: retoma em repouso no local salvo. Itens de missão mantêm o sistema original. Falha extrema abaixo do mapa remove o objeto opcional, sem esconder teleporte de recuperação.

Quebra usa estado pré-definido: oculta corpo, remove colisões, cria até três fragmentos visuais que são projetados no piso e limpos em oito segundos. Limite global de 12 fragmentos. Não é fratura volumétrica ou simulação de cacos. Armários e máquinas não quebram.

Regras Firestore aceitam somente IDs e estrutura conhecidos, coordenadas/rotações limitadas e estados corretos. Campo opcional mantém compatibilidade com checkpoints antigos. Cada estado usa `t: "x,y,z;rx,ry,rz"` com duas casas e flag broken; a expressão regular limita cada posição a ±50 e rotação a ±3,15. Essa representação cabe no orçamento de expressões do Firestore para os 12 objetos juntos. O cliente também valida valores finitos e intervalos antes de restaurar, e lê arrays locais de desenvolvimento como migração. O codec cloud preserva arrays de float quando utilizados em outros campos. IDs novos exigem atualização das regras.

Base técnica: [RigidBody3D/estado de contato](https://docs.godotengine.org/en/stable/classes/class_physicsdirectbodystate3d.html) e [AnimatableBody3D](https://docs.godotengine.org/en/stable/classes/class_animatablebody3d.html).
