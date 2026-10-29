# ECOS — Instalação Abandonada

Protótipo vertical de survival horror 3D nativo em GDScript. Projeto independente; nenhum arquivo do Desolação RPG foi alterado. Desenvolvido e testado com **Godot 4.7.2 stable**, renderer Mobile (Vulkan). Arte geométrica, criatura 3D e sons sintetizados são provisórios e originais.

## Executar

1. Importe `project.godot` na Godot 4.7.2 e pressione **F6 na cena main** ou **F5**.
2. Escolha nova sessão e jogar com ou sem microfone. Com microfone, fique em silêncio por três segundos. Use fones.
3. Lanterna na mesa da enfermaria → fusível na manutenção → gerador na energia → cartão na segurança → saída no extremo do corredor.

No workspace entregue, `Jogar.bat` usa a engine portátil em `../.tools/godot`, se presente. É possível informar outro executável na variável `GODOT_EXE`.

| Tecla / gesto | Ação |
|---|---|
| WASD / arrastar lado esquerdo | Mover |
| Mouse / arrastar lado direito | Olhar |
| Shift / CORRER | Correr (botão de toque alterna) |
| C / AGACHAR | Alternar agachamento |
| E / INTERAGIR | Usar, coletar, esconder ou sair |
| F / LANTERNA | Alternar lanterna |
| Tab / MOCHILA | Consultar itens |
| Esc / PAUSA | Pausar |

## Entrega

- `scenes/main/main.tscn`: menu, consentimento, carregamento e término.
- `scenes/levels/facility.tscn`: planta modular construída em tempo de execução e navigation mesh.
- `scenes/player/player.tscn`: CharacterBody3D, câmera, lanterna e interação.
- `scenes/enemy/creature.tscn`: criatura 3D animada por código, nove estados e NavigationAgent3D.
- `scenes/ui/hud.tscn`: joystick, área de olhar, botões e indicadores.
- `scripts/interactions/interactable.gd`: portas, itens, gaveta, documento, gerador, distração, saída e armários.
- Autoloads: Game (estado/saves), NoiseBus (eventos/oclusão), Mic (captura/RMS), Sound (áudio espacial).
- `assets/audio`: dez WAVs originais. `assets/icon.svg`: ícone original.
- `tests`: testes de integração e captura visual. `docs`: projeto, arquitetura e plano de validação Android.

## Testes

```powershell
godot --headless --path . res://tests/runner.tscn
godot --path . res://tests/visual.tscn
```

A suíte tem 43 verificações e restaura o checkpoint do usuário após a execução. Testes de toque usam eventos sintéticos: não certificam touchscreen físico. Não abra uma sessão de jogo simultânea à suíte, que usa o diretório de dados do mesmo projeto. A captura visual gera `docs/menu.png` e `docs/gameplay.png`.

## Limites desta versão

Microfone e permissões Android exigem validação em aparelho real. Os limiares de áudio são **valores iniciais relativos ao piso calibrado**, não um balanceamento validado. Os perfis gráficos não constituem medição de FPS. Arte e animações são placeholders; navegação é baked ao carregar, e portas têm animação provisória de painel retrátil. A criatura pode abrir portas; paredes permanecem sólidas. Não há combate ou bateria escassa. Consulte `docs/TESTES_ANDROID.md` antes de considerar a versão pronta para distribuição.

Exportação local não publica em lojas. Veja os presets e as instruções Android na documentação.
