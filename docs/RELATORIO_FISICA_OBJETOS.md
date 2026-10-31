# ECOS 0.6 — materiais e mundo físico

Implementado diretamente sobre a 0.5, na branch `feature/physical-world-materials`. Não houve recriação do projeto. Login, objetivos, IA, microfone, inventário, terror e checkpoints anteriores foram preservados.

## Auditoria e objetos

O inventário inicial percorreu a fase gerada por scripts: 664 registros de malhas, corpos e formas. O levantamento final contém 798 registros, não 798 props independentes. Antes: 188 StaticBody3D, dois personagens, 190 formas e 284 malhas. Depois: 206 estáticos (incluindo proxies apenas de navegação), 12 RigidBody3D, sete AnimatableBody3D, dois personagens, 242 formas, 328 malhas e um sensor. Não havia juntas físicas e não foi criada uma rede de juntas desnecessária.

Dados por nó e origem: [antes](INVENTARIO_FISICA_before.json), [depois](INVENTARIO_FISICA_after.json). Cada registro informa identificador, cena/script, tipo, material/texturas, colisão, gravidade/movimento, interação, massa de gameplay, sons e custo previsto. Famílias e massas estão no [guia de física](SISTEMA_FISICA_OBJETOS.md).

Props ativos: lata, garrafas, ferramentas (uma dentro da gaveta), caixas, cadeira, carrinho, balde e esfera de borracha. Podem cair, colidir, tombar ou rolar conforme forma e massa. Leves podem ser segurados e arremessados; médios podem ser arrastados no chão. Armários, gerador, prensa, bancadas e estruturas ficam ancorados. Cabos finos, manchas e detritos de borda continuam decoração agrupada.

## Materiais e colisões

Dez novos PBRs complementam os dez existentes: metal escovado, aço molhado, vidro sujo/trincado, plástico, borracha, madeira úmida, chapa, musgo e estofado. São sínteses originais 256/128 com albedo, normal e ORM; Resources e gerador estão versionados. Materiais físicos reutilizáveis para sete superfícies definem atrito e restituição.

Corrigidos: lata antes suspensa/animada manualmente, peças coletáveis no ar, altura e tamanho de colisão dos pickups, pedestal da chave, posição dos consoles, apoio do rádio e colisão de objetos fixos. Cama/prensa/carrinho decorativo receberam hulls simplificados. Gaveta e cadeira foram reposicionadas após a verificação de circulação. A prateleira da garrafa foi encostada à parede para liberar a galeria.

O novo sistema usa RigidBody3D e gravidade nativa, CCD, sleeping e formas simples/compostas. Jogador e criatura colidem e empurram props. Móveis ancorados fora da NavigationRegion têm proxies exclusivos na camada 32 para o bake; essa camada não duplica colisões de gameplay. Isso corrigiu rotas que antes atravessavam a bancada de esconderijo. Props móveis ficam fora do bake.

## Interação e som

R mantido/SEGURAR manipula leves por mola de força limitada, sem teleporte ou colisão desativada. R/ARRASTAR em médios usa força horizontal. Soltar o botão larga; Q arremessa leves e solta médios. E continua interação contextual. Parede, distância, massa, força e tempo preso limitam o controlador. Esconderijo, pausa e derrota liberam a manipulação.

Cinco portas giram até 90° em folhas físicas, preservando trancas, energia e navegação. Gaveta desliza até 36 cm, tem fundo, laterais, conteúdo e estado salvo. Corrente usa links instanciados, sensor e balanço amortecido; não simula cada elo separadamente.

PhysicsImpactAudio lê velocidade relativa e posição de contato no solver. Sete bancos/21 WAVs sintetizados distinguem metal, madeira, vidro, borracha, peso, corrente e deslizamento. Limiar e cooldown evitam pequenos contatos incessantes; um único dono relata colisões entre dois props. Evento sonoro e som espacial partem da mesma decisão. A criatura investiga o impacto real, sem saber automaticamente onde está o jogador.

Quebráveis usam estados pré-definidos e fragmentos visuais limitados/temporários, sem fratura complexa. A física não pretende substituir uma simulação industrial.

## Persistência e Firebase

`world.physics` salva transformações e quebra de IDs conhecidos, além da gaveta. Retoma em repouso; não salva velocidades ou objeto ainda preso à mão. Snapshot ocorre periodicamente e antes de salvar. Campo opcional mantém checkpoints 1/2 compatíveis. Regras Firestore validam estrutura, IDs e limites. Transformações usam texto numérico compacto validado por expressão regular. O emulador confirmou que a validação anterior de arrays dos 12 corpos excedia o [limite de 1.000 expressões do Firestore](https://firebase.google.com/docs/firestore/quotas); o formato compacto passou com 0, 1, 4, 8 e 12 corpos. O codec também preserva floats em arrays, evitando conversões indevidas quando esses tipos são utilizados.

Os testes reais do Firebase confirmaram upload e restauração do estado físico, isolamento entre contas, pontuação, melhor tempo e fila offline. Contas/documentos de QA são temporários e removidos após uso. Hosting Firebase continua separado da hospedagem do jogo no Cloudflare.

## Testes executados

- Baseline anterior: 69 verificações passaram.
- Regressão atual: 79 passaram; dez verificações adicionais vêm dos novos materiais.
- Expansão: 41 passaram, aguardando agora a abertura real da folha da porta.
- Terror/capturas: 23 passaram.
- Física: 47 passaram. Queda, repouso/sleeping, atrito comparado, impulso/rolamento, CCD em parede, manipulação, arrasto sem levantar, arremesso limitado, gaveta, balanço amortecido, quebra, limite de fragmentos, cooldown, deduplicação, fonte sonora, reação da IA, 12 quedas simultâneas, passagem da criatura e restauração foram exercitados.
- Firebase real: 20 verificações incluem estado dos 12 corpos, restauração e rejeição de transformações fora de limite ou malformadas. Falhas anteriores de codec e orçamento das regras foram diagnosticadas e corrigidas antes da entrega.
- Travessia completa: Fácil, seed 70421, entradas de movimento/visada reais e criatura ativa, sem teleporte. Completou fusível, painel, gerador, cartão e saída com 1.100 pontos. A rota usa a galeria para perder perseguição; tentativas de voltar diretamente pelo caminho da criatura terminaram em derrota. Isso não certifica equilíbrio de todas as dificuldades.

Total previsto dos cinco conjuntos atuais de verificações: 210; o resultado final do Firebase será confirmado após a publicação das regras compactas. Capturas desktop em `docs/review/physics`, geradas por `tests/physics_review.tscn`; inspeção visual corrigiu enquadramento e folgas dos móveis. Métricas: 37–175 draw calls e aproximadamente 74,2 MB de memória estática monitorada, sem equivalência a FPS ou RAM total Android.

## Limitações e pendências

Sem dispositivo Android conectado no adb. FPS sustentado, aquecimento, bateria, RAM real, latência, microfone/eco e ergonomia de múltiplos dedos precisam de testes físicos. Texturas, sons e destruição são procedurais/simplificados; vidro é opaco, carrinho não tem suspensão física e corrente não possui solver de elos. Não se afirma realismo fotográfico ou precisão industrial.

Corpos essenciais não são desligados no baixo. Props secundários distantes e praticamente parados podem congelar; objetos em queda continuam simulados. Limites normais: até 16 props do gerenciador, oito arremessáveis temporários e 12 fragmentos visuais. Não há pooling desnecessário nesta escala.

## Arquivos e guias

Núcleo novo: `scripts/physics/{object_profile,surfaces,physical_prop,impact_audio,manipulator,character_push,mechanism,hanging_prop,world_physics}.gd`; perfis e PhysicsMaterials em `resources/physics`; áudio em `assets/audio/impacts`; PBRs em `assets/materials` e `assets/textures/pbr`. Geradores `tools/art/generate_physics_materials.py` e `generate_impact_audio.py`.

Integrações em player/HUD, creature, interactable/throwable, facility/facility_art, Game, Cloud, diretor/eventos, Sound, regras Firestore e presets. Testes novos physics_runner, physics_inventory e physics_review; regressões e cloud_runner atualizados. Pacotes da 0.6 ficam em `builds/physics`, fora do Git; fontes e documentação estão na branch.

[Física](SISTEMA_FISICA_OBJETOS.md), [PBR](BIBLIOTECA_MATERIAIS_PBR.md), [interação](INTERACAO_OBJETOS_3D.md), [áudio](AUDIO_IMPACTOS.md), [Android](OTIMIZACAO_FISICA_ANDROID.md).

Links de publicação, assinatura e verificação do navegador serão anexados após a validação dos pacotes.
