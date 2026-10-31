# ECOS 0.5 — reformulação visual e terror

Branch: `feature/horror-visual-creature-jumpscares`, criada a partir da expansão 0.4. Auditoria inicial: [AUDITORIA_TERROR_VISUAL.md](AUDITORIA_TERROR_VISUAL.md).

## Entrega

- Sinalização física reutilizável substitui textos de orientação flutuantes; painel, rebites, desgaste, face única e oclusão. Avisos narrativos e mapa físico complementam enfermaria, manutenção, depósito, segurança e energia.
- Carrinho e roupa hospitalar, ferramentas, caixas, quadros elétricos e cabos acrescentam identidade às salas, respeitando circulação e objetivos.
- Escutador v2 original: derme remalhada, assimetria corporal, cabeça/mandíbula/conchas redesenhadas, UV/PBR, rig de 29 ossos, LODs de 11.144/5.126 triângulos e 23 clipes. Fonte Blender e gerador incluídos.
- Doze bancos sonoros com duas variações cada, reprodução espacial, cooldowns e mixagem de captura. São sínteses originais, não gravações profissionais.
- Oito capturas selecionadas por contexto, validação de proximidade/visão ou esconderijo confirmado, controle exclusivo, sincronização de áudio e câmera reduzível/desativável.
- HorrorDirector com tensão 0–5, alívio após perseguição, nove eventos configuráveis e checkpoint de histórico, contagens, cooldown e RNG. Presença usa a criatura real, sem cópias ou teleporte.
- Preferências de movimento da câmera, efeitos visuais e variação de luz; iluminação suave sem estrobo. Microfone continua opcional e não dispara susto diretamente.
- Firestore aceita o novo estado opcional, mantendo checkpoints antigos e isolamento entre contas. Hosting Firebase não foi alterado; sua função principal continua autenticação e progresso.

## Arquivos principais

Componentes novos: `scripts/world/world_sign_3d.gd`, `scenes/world/world_sign_3d.tscn`, seis scripts em `scripts/horror`, Resources em `resources/horror/{audio,captures,events}`. Integrações: `facility.gd`, `facility_art.gd`, `creature.gd`, `escutador_visual.gd`, `interactable.gd`, `player.gd`, `hud.gd`, `game.gd`, `main.gd`, `sound.gd` e `firestore.rules`.

Assets novos: `assets/models/escutador_v2*.glb`, texturas exportadas, manifesto JSON, `assets/source/escutador_v2.blend`, WAVs/manifesto em `assets/audio/creature_v2` e `electric_hum.wav`. Geradores: `tools/art/build_escutador_v2.py`, `tools/art/generate_horror_audio.py`.

Entrega web: `hosting/horror.html`, compressão WASM/PCK em `prepare.py`, normalização de resposta em `wasm-loader.js` e cabeçalhos gzip. Exportações 0.5 ficam em `builds/horror`, ignorado pelo Git. Presets mantêm ARM64 e renderer Compatibility. Novos testes: `horror_runner.*`, `horror_review.*`; regressões e teste cloud foram atualizados para capturas e estado opcional.

## Validação

69 verificações de regressão, 41 da expansão, 23 novas de terror e 18 testes reais de Firebase passaram, incluindo checkpoint com histórico do diretor. A fase inteira passou em Fácil, seed 70421, com movimento físico e criatura ativa, usando rota lateral, distração, painel, gerador e saída: 1.100 pontos. O teste usa entradas automatizadas e aceleração de tempo; não representa certificação de equilíbrio de todas as dificuldades.

Revisão gráfica gerou 14 imagens em `docs/review/horror`, incluindo salas, leitura das placas, escuta e poses das oito capturas. Métricas desktop: 22–185 chamadas de desenho e aproximadamente 72 MB de memória estática monitorada; não representam RAM total ou FPS Android. A inspeção corrigiu câmera de manutenção que inicialmente estava dentro de um armário.

APK 0.5.0/código 5 ARM64 exportado, assinatura debug v2/v3 verificada e permissões INTERNET/RECORD_AUDIO conferidas no manifesto. Build tools usou fallback 30.0.3 por ausência da versão do Target SDK; a exportação concluiu. Nenhum dispositivo foi listado por adb.

Regras Firestore publicadas apenas para compatibilidade do novo checkpoint. Contas e documentos criados pelos testes são temporários e removidos após validação. Resultados de publicação e navegador serão registrados na conclusão deste relatório.

## Limites e próximos testes

O modelo e as animações têm autoria procedural real, com acabamento manual de escultura/retopologia e contatos ainda necessário. A abertura visual do armário é provisória. As poses de captura foram renderizadas, mas cada contexto ainda deve receber revisão humana durante jogo real. Áudio precisa de avaliação com fones e alto-falante do telefone. Não há garantia de aparência cinematográfica ou desempenho sustentado com base em testes desktop.

Pendentes em aparelhos: FPS, calor, bateria, memória, permissões e sensibilidade do microfone, eco, ergonomia touch e alternância de foco durante captura. Use a mesma conta em dois aparelhos para conferir continuidade. O código guarda cooldown global e máximos entre checkpoints; relógios individuais dos eventos reiniciam ao carregar.

## Guias

[Placas](PLACAS_E_SINALIZACAO_3D.md), [criatura](REDESIGN_CRIATURA.md), [áudio](AUDIO_CRIATURA.md), [capturas](SISTEMA_JUMPSCARES.md), [diretor](HORROR_DIRECTOR.md), [Android](OTIMIZACAO_TERROR_ANDROID.md).
