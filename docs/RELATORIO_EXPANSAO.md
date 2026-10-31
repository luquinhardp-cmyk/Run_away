# Entrega — expansão de sobrevivência 0.4

Branch `feature/survival-horror-gameplay-expansion`, a partir de `7f08606`. Godot 4.7.2 stable. O relatório de auditoria foi escrito antes de alterar scripts; referência de 69 testes aprovada.

## Sistemas entregues e reaproveitados

1. **IA:** controlador, NavigationAgent3D, rig e clipes existentes preservados. Componentes novos separam perfil, visão, memória e planejamento da busca. Visão acumulada, cooldown de escuta e memória sonora distinta evitam perseguição onisciente. Busca em armários exige pistas, aproximação e aviso; captura exige condições reais.
2. **Ruído:** Resource tipado, sinal novo e contrato antigo compatível. Distância, obstáculos e intensidade alimentam o mesmo sistema para passos, portas, microfone, impactos, dispositivos e gerador.
3. **Mapa:** 21 células originais mais sete da galeria/oficina, mantendo pátio e subsolo. Rotas longa/curta, atalho com chave, bancada e marcadores de busca. Bloqueios reais atualizam a navegação sob demanda.
4. **Objetos:** cena reutilizável de peça metálica física, coleta/seleção/arremesso, impactos, limite e descarte. Rádio e alarme com áudio espacial original e estímulo em posição real. Portas impedem fechamento sobre corpos. Painel/gerador têm indicador visual de estado.
5. **Objetivos:** Resources com pré-requisitos e estados derivados. Fusível exige instalação antes de ligar o gerador; cartão e saída exigem energia. Chave específica do depósito abre oficina. Apagão permite reativar sem perder componente nem pontos já conquistados.
6. **Microfone:** captura/permissões/RMS/calibração/privacidade existentes preservados. Histerese, adaptação lenta a ruído constante e guarda curta de efeitos próximos reduzem falsos positivos. Sem alegação de cancelamento de eco ou validação acústica real.
7. **Eventos:** impacto no depósito, cano físico caído e apagão com alarme, prioridade/cooldown/probabilidade/estado persistente. Seed reproduz variante do fusível e ordem de patrulha; dificuldade e configuração persistem por sessão.
8. **Persistência/UI:** checkpoint v2 aceita migração de v1, mantém seed, eventos, atalhos e peças. Pontos, login, fila e resultados atômicos Firebase preservados. Regras retrocompatíveis preparadas e aplicadas sem alteração de Hosting. HUD ganhou apenas ARREMESSAR contextual; mochila informa seleção e objetivo opcional. Configurações expõem dificuldade, seed e métricas.

Cena de produção nova: `scenes/interactables/throwable.tscn`. Cenas de teste novas: `expansion_runner`, `playthrough` e `expansion_review`. As cinco cenas originais continuam sendo usadas. Nenhum autoload novo.

## Validação

| Execução | Resultado |
|---|---|
| `tests/runner.tscn` | 69 verificações passaram |
| `tests/expansion_runner.tscn` | 41 verificações passaram: ruídos, portas/LOS, navegação física, chave/atalho, painel, eventos/recuperação, rádio/alarme, impacto real, cap de corpos, memória/busca, armário avisado, microfone sintético e save |
| `tests/cloud_runner.tscn` | 18 verificações online passaram, incluindo v1/v2, chave opcional sem pontos extras, isolamento entre contas, fila persistente, reenvio sem duplicação e renovação; contas/documentos temporários removidos |
| `tests/playthrough.tscn` | Partida completa na dificuldade Fácil, seed 70421: cápsula e criatura ativas, nenhuma mudança artificial de posição/estado durante o percurso; interações pela mira; rádio, circuito lateral, painel/gerador, cartão e saída; vitória com 1.100 pontos |
| `tests/expansion_review.tscn` | Quatro capturas reais em Compatibility/Intel UHD, incluindo galeria, oficina, painel e HUD touch; imagens e métricas em `docs/review/expansion/` |

O percurso automatizado testa uma estratégia específica. Tentativa direta pela porta da segurança terminou em captura; a volta pela galeria permitiu escapar no Fácil. A mesma estratégia automatizada também perdeu no Normal: não é um teste de balanceamento humano aprovado para as três dificuldades. Os testes de cenários exercitam perseguição, perda visual, esconderijo e distração separadamente. O percurso inteiro não finge um teste manual em celular.

Snapshots de revisão: 20–151 draw calls, 1.068–27.572 primitivas, aproximadamente 70–71 MB de memória estática informada pela engine. São vistas específicas no desktop, sem benchmark de FPS/Android. Métricas locais opcionais incluem custo de IA, criação de áudio e RMS, contagem física, frames e memória.

## Builds e publicação de testes

Builds isolados em `builds/expansion/`; APK usa versionCode 4, versionName 0.4.0. A autorização de publicação de testes já concedida permite uma **prévia de branch** no Cloudflare e uma nova pré-release no GitHub, preservando produção 0.3 e assets anteriores. Não implantar esta branch como branch de produção por engano. Firebase permanece como backend; apenas regras retrocompatíveis mudaram.

```powershell
godot --headless --path . --export-release Web builds/expansion/web/play/index.html
python hosting/prepare.py --output builds/expansion/web --landing hosting/expansion.html --apk-url https://github.com/luquinhardp-cmyk/Run_away/releases/download/v0.4.0-gameplay/ecos-android.apk
godot --headless --path . --export-debug Android builds/expansion/ecos-android.apk
```

## Limites e pendências reais

- Sem aparelho conectado: microfone acústico, permissões/multitouch físicos, FPS mobile, calor e bateria continuam pendentes. Meta de 30 FPS não foi declarada aprovada.
- Busca/acústica são aproximações; iluminação usa exposição explícita, não leitura de luminância. O bake sob demanda ainda é síncrono. Os gráficos originais continuam em polimento.
- Corpos arremessados ativos não persistem; coleta/consumo persistem. Rádios desligam ao recriar a fase. Saves retomam na enfermaria, como antes.
- Ao testar progresso entre aparelhos, usar a versão 0.4 em ambos. Um cliente 0.3 pode salvar seu formato antigo e descartar os campos de mundo que desconhece.
- A pontuação é pessoal e reportada pelo cliente, sem promessa de ranking competitivo protegido.

Guias: `IA_CRIATURA_AVANCADA.md`, `MAPA_INTERCONECTADO.md`, `INTERACOES_E_DISTRACOES.md`, `OBJETIVOS_E_ENIGMAS.md`, `MICROFONE_BALANCEAMENTO.md`, `EVENTOS_DINAMICOS.md`, `OTIMIZACAO_ANDROID.md`. A lista de arquivos desta entrega está em `ARQUIVOS_EXPANSAO.md`.
