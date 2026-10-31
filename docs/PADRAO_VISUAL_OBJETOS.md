# Padrão visual dos objetos

Terror rural/industrial decadente: madeira úmida, pintura envelhecida, metal com patina fina, tecido gasto, vidro sujo. Materiais diferentes por componente, evitando aplicar ferrugem a lentes, borracha ou isolantes. Aço envelhecido usa `weathered_iron`; metal de contato usa `brushed_metal`; mangueiras e pneus usam `worn_rubber`; isolantes/plásticos, `aged_plastic`; madeira usa `rotten_wood`/`damp_wood`. O PBR existente e o céu noturno são preservados.

Unidades em metros. Câmera FPS permanece a 1,56 m; alcance de interação e tamanho dos atores não mudam. Modelos ocupam o espaço anterior: portas de serviço 2,6 m altas e 1,8 m largas, adequadas à criatura; bancadas principais com topo a 0,725 m; cadeira de cerca de 0,9 m com assento próximo de 0,45 m. As portas industriais existentes são maiores que a referência residencial de 2,0–2,2 m; não se encolheu o jogador para compensar.

Chave: 0,22 m, espessura visual 0,014 m, aro realmente vazado, haste e três dentes. Colisor de interação mantém área tolerante, e o visual repousa no suporte a 0,843 m. Cartão ganha espessura de 8 mm e repousa na bancada. Lanterna mantém 0,34 m; fusível 0,18 m com contatos/isolante. Ranhuras, quinas, aberturas e alças alteram a silhueta; riscos e oxidação ficam nos mapas PBR. As medidas de objetos físicos continuam compatíveis com os seus perfis.

UV1 é gerada no Blender por Smart Project com densidade tiled ajustada à área em metros. Sobrepor ilhas para reutilizar uma textura repetível é intencional; não há atlas único esticado sobre uma máquina inteira. Malhas importadas usam UVs, não triplanar mundial; arquitetura de superfícies longas mantém triplanar para escala consistente. Normal e ORM utilizam a convenção existente: R oclusão, G rugosidade, B metalicidade. Mapas de arranhões não substituem dentes, encaixes ou nervuras que precisam de geometria.

Colisores são aproximações estáveis. Não se adicionam colisões a cada parafuso, ranhura ou folha. Corpos dinâmicos mantêm centro, massa, sons e comandos; superfícies decorativas de poucos milímetros se apoiam nos pisos existentes para evitar pequenos degraus. Os modelos leves mantêm componentes reconhecíveis, com menos geometria.

Pendências artísticas: refinamento manual de desgaste localizado, variações de acabamento por história de cada peça e revisão perceptiva em telas pequenas. Modelos procedurais funcionais não são anunciados como assets fotorealistas finalizados.
