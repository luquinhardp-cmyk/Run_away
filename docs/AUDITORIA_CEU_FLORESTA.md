# Auditoria anterior — céu e floresta

Base: ECOS 0.6, branch `feature/blood-moon-dark-forest` criada sem alterações locais pendentes.

Mundo: `scenes/levels/facility.tscn` é construído por `facility.gd`. Exterior jogável ocupa aproximadamente x ±11 e z 2–21; edifício se estende até z −42 e subsolo a oeste. Cercas, portão, rampa, rotas e saída precisam permanecer funcionais. O exterior atual tem poucas árvores nuas, vegetação instanciada e cercas desenhadas por `facility_art.gd`; os limites físicos já existem.

Environment atual usa fundo de cor, ambiente 0,38 e fog 0,017, sem Sky e sem sol direcional. Há luz quente de poste e um preenchimento azul externo relativamente forte. Não há lua ou estrelas. O ambiente interno depende dessa luz ambiente: não reduzir globalmente sem considerar teto/localização.

Câmera FPS pertence ao jogador; movimento/efeitos têm acessibilidade. Microfone, NoiseBus e Sound são independentes da renderização. HorrorDirector mantém tensão, active_until, since_scare, since_chase e cooldown. O novo evento deve respeitá-los, sem alimentar a IA terrestre com sons celestes falsos ou roubar a câmera.

Perfis existentes controlam resolução, mapas e LOD. Alvo Android usa renderer Mobile; WebGL 2 usa Compatibility. Não usar volumetria, milhares de nós de estrelas ou física por folha. Floresta deve ser instanciada por grupos com culling, mantendo cobertura em todos os perfis. Entidade alada será apresentação/evento, sem segunda IA de caça.

O sistema novo será isolado em scripts/ambiente e recursos próprios. Não haverá troca do monstro terrestre nem alteração de objetivos. Testes desktop e exports não certificam FPS, temperatura, microfone ou ergonomia em Android físico.
