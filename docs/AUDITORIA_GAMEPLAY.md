# Auditoria antes das alterações — expansão de gameplay

Base: commit `7f08606`, Godot **4.7.2.stable.official.ed1daf0bf**, branch de trabalho `feature/survival-horror-gameplay-expansion`. Referência executada antes de alterar scripts: **69 testes passaram, zero falhas**. `adb devices` não encontrou aparelho. Inspecionados scripts, cinco cenas `.tscn`, Resources PBR, autoloads, configuração, InputMap em runtime, grupos/sinais, saves locais/Firebase e presets Android/Web.

| Funcionalidade | Classificação e evidência |
|---|---|
| FPS, câmera, corrida, agachamento, lanterna | Implementada e funcional nos testes físicos; não validada em aparelho real |
| Touchscreen/multitouch | Implementada e funcional com eventos sintéticos; hardware pendente |
| Microfone, consentimento, RMS, calibração, pausa/background | Implementada parcialmente: pipeline real e testes sintéticos; falta histerese/adaptação para ruído contínuo e validação acústica real |
| Criatura, rig, animações, jumpscare | Implementada e funcional; 29 ossos, 12 clipes, ataque e captura conectados |
| Perseguição e percepção | Existente, mas com problemas: som altera última posição visual até durante perseguição; visão binária e distâncias fixas |
| Memória e busca | Implementada parcialmente: um único ponto aproximado; `heard_hide` consulta posição real do jogador e pode causar captura sem pista local suficiente |
| Navegação | Implementada parcialmente: NavigationAgent3D, bake inicial e recuperação de portas; faltam seleção de pontos acessíveis e rotas alternativas |
| Mapa | Implementada parcialmente: 21 células, pátio e subsolo conectados; corredor principal com salas laterais, sem circuito alternativo útil |
| Armários | Implementada parcialmente: câmera e oclusão funcionam; faltam identidade, ocupação, investigação avisada e saída validada |
| Inventário, portas e interações | Implementada parcialmente: um script comum; faltam requisitos declarativos, chaves específicas e prevenção de fechar sobre corpos |
| Objetivos, gerador, fuga | Implementada e funcional no fluxo básico fusível → energia → cartão → saída; estados derivados em texto, sem Resources de objetivos |
| Arremessáveis | Não implementada: lata apenas roda visualmente e emite som |
| Rádio/alarme | Não implementada |
| Eventos e variações reproduzíveis | Implementada parcialmente: um impacto roteirizado e oscilação de lâmpada; sem seed/cooldown/persistência geral |
| Materiais, iluminação e áudio espacial | Implementada e funcional; 10 PBRs, mapas 512/256, LOD da criatura, batching por material/região, 17 WAVs |
| Salvamento/menu/configurações | Implementada e funcional: checkpoint seguro, timer ativo, dados locais por conta, fila Firebase, totais atômicos; contrato Firestore precisa evoluir junto do checkpoint |
| Dificuldades/configuração de IA | Não implementada como Resources |
| Métricas Android | Implementada parcialmente: contagens gráficas anteriores; sem custo de IA/áudio nem benchmark físico |

Autoloads existentes: Game, Cloud, NoiseBus, Mic e Sound. Principais sinais: Game.updated/ended, Cloud.changed, NoiseBus.emitted, Mic.status_changed, interactable.notified e facility.message. Grupo atual: `doors`. Máscaras: mundo 1, jogador 2, criatura 4, interação 8. Cenas finas instanciam a geometria e os componentes por script; preservar esse padrão sem adicionar singletons desnecessários.

Riscos: bake síncrono inicial, quantidade de luzes sem sombras, percepção e interação por raycasts, sons instanciados sem limite global, persistência em JSON e nova compatibilidade do backend. Plano: dados de ruído/IA/objetivos/eventos em Resources, memória sem acesso oculto ao alvo, circuito lateral com atalhos e dispositivos, física limitada, eventos recuperáveis e testes de percurso/objetivos. Builds desta revisão serão gerados em diretório separado para revisão; não substituir os builds de produção durante a implementação.
