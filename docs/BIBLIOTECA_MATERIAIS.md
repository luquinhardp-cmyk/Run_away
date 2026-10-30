# Biblioteca de materiais PBR

Dez materiais originais, cada um com três mapas em 512² e os equivalentes em 256²: **60 PNGs**, além de uma prancha de revisão. `assets/materials/` contém dez recursos StandardMaterial3D editáveis; `HorrorArt` cria instâncias compartilhadas e escolhe a resolução pelo perfil.

| Prefixo | Aparência | Aplicação |
|---|---|---|
| aged_concrete | concreto manchado, trincas esparsas | paredes e fachada |
| damp_concrete | umidade e escorridos | subsolo / rodapés |
| cracked_floor | piso desgastado com fissuras | piso interno |
| peeling_plaster | reboco irregular e descascado | teto |
| rusted_iron | ferro exposto, oxidação e fixadores | portas, máquinas, tubos, corrente |
| rotten_wood | fibras e tábuas gastas | cerca, caixas, mobiliário |
| mud_leaves | lama, resíduos de folhas e terra | terreno exterior |
| torn_fabric | trama, manchas e desgaste | colchão, pano sobre caixas, papel antigo estilizado |
| organic_residue | resíduos escuros e rugosidade variável | manchas, marcas, cartilagem |
| creature_skin | poros, dobras e variação terrosa | pele e placas de queratina |

O nome torn_fabric descreve a superfície; rasgos reais dependem da geometria do objeto. Esta textura não recorta automaticamente furos na malha.

## Arquivos e canais
Para cada prefixo: `_albedo.png`, `_normal.png`, `_orm.png`; versões pequenas terminam em `_low.png`. ORM: **R = ambient occlusion; G = roughness; B = metallic**. Rugosidade, metal e AO são canais reais calculados, não apenas nomes de arquivos. Normal tangent-space gerado por derivadas de altura periódica. Os materiais selecionam explicitamente os canais corretos na Godot.

Metallic se concentra nas áreas sem ferrugem do ferro; concreto, madeira e pele são dielétricos. Emission fica restrita às lâmpadas e ao pequeno refletor da lanterna coletável; pele e olhos não emitem luz. Poças usam geometria opaca irregular e roughness baixa, sem transparência ou refração caras. Não simulam reflexos de ambiente completos.

## Repetição e importação
Ruído periódico com semente 197804 e distâncias toroidais para continuidade das texturas. Triplanar em espaço global para arquitetura; UVs reais para o modelo animado. `mipmaps/generate=true` e `compress/mode=2` nas configurações importadas. Foram gerados formatos S3TC e ETC2/ASTC pela engine. Mapas normais têm modo de normal explicitado. O perfil baixo desativa normal/AO no shader e carrega mapas de 256².

## Reproduzir
Na raiz do projeto, com Python/NumPy:

```powershell
python tools/art/generate_materials.py
python tools/art/generate_material_resources.py
```

As configurações `.png.import` versionadas preservam compressão e mipmaps após regerar PNGs. O Blender usa os mapas da criatura na exportação; para mudar esses mapas no GLB, rode também `build_escutador.py` no Blender. Não é necessário Blender para executar o jogo entregue, que importa GLBs.

`assets/textures/pbr/manifest.json` registra semente, mapas e proveniência. Os mapas são procedurais, não escaneados ou fotografados. Não há pixels, marcas ou texturas baixadas das referências. Recursos originais destinados ao projeto; licença pública de redistribuição ainda não definida pelo titular.

Ao importar os GLBs autocontidos, a Godot extrai cópias de suas imagens em `assets/models/`. Essas cópias automáticas usam os mesmos mapas originais; não são novos materiais autorais. O GLB pode ser visualizado texturizado fora da Godot.
