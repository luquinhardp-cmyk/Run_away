# Validação e exportação Android

## Resultado desta entrega — 29/10/2026

| Verificação | Resultado |
|---|---|
| Importação / compilação Godot 4.7.2 stable | Passou |
| Suíte de integração headless | 43 passaram, 0 falharam |
| Renderização Mobile Vulkan / Intel UHD | Passou; capturas menu.png e gameplay.png |
| Empacotamento Android ARM64 | APK debug exportado e assinado localmente |
| Build Windows x86_64 | Exportado com PCK incorporado |
| Aparelhos via ADB | Nenhum conectado |
| Microfone físico / permissões Android | Não validado |
| Multitouch físico / recortes de tela | Não validado |
| FPS / temperatura / bateria Android | Não medidos |

Os testes exercitam movimento, corrida, agachamento, câmera, parede, dedos independentes por eventos sintéticos, contrato de ruídos, lanterna, portas, objetivos, fusível/gerador/cartão, armários, visão, oclusão sonora, RMS, níveis relativos, pausa, segundo plano, patrulha navegada, transições da IA, vitória, checkpoint, derrota e retorno ao menu. Captura física de áudio não é simulada nem declarada validada. A suíte não cobre todos os gestos, balanceamento ou cenários de falha de armazenamento.

## Exportar novamente

1. Instale Godot **4.7.2 stable** e os export templates da mesma versão (Editor → Gerenciar modelos de exportação).
2. Instale Android SDK e JDK. Nas configurações da engine, informe o caminho do SDK Android e Java SDK. Nesta máquina, o JDK funcional está em `C:/Program Files/Android/Android Studio1/jbr` e o SDK em `%LOCALAPPDATA%/Android/Sdk`.
3. Abra Projeto → Exportar → **Android**. O preset usa ARM64, renderer Mobile, RECORD_AUDIO habilitada, INTERNET desabilitada, sem backup de dados e assinatura debug local.
4. Exporte em `builds/ecos-android.apk`, ou execute:

```powershell
godot --headless --path . --export-debug Android builds/ecos-android.apk
```

Esta versão exporta diretamente pelo template APK, sem Gradle customizado. O SDK mínimo/alvo vem do template da engine. O exportador local usou Build Tools 30.0.3 como fallback por não encontrar a versão correspondente ao target do template; alinhamento, assinatura e verificação do APK passaram. Para distribuição futura, instalar ferramentas correspondentes à versão da engine e conferir requisitos vigentes da loja. Não publicar o APK debug em lojas.

Documentação oficial: [exportar para Android](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html). A página recomenda OpenJDK 17; a instalação disponível nesta máquina foi usada para a assinatura de teste.

## Instalar para teste autorizado no seu aparelho

Ative depuração USB e conecte um celular compatível com Vulkan e ARM64. Depois:

```powershell
adb devices
adb install -r builds/ecos-android.apk
adb shell am start -n org.ecos.instalacaoabandonada/com.godot.game.GodotApp
```

Se o nome da Activity diferir no template, abra o aplicativo pelo ícone ECOS. Uma assinatura diferente de outra instalação com mesmo pacote exige tratamento manual; não apagar dados sem necessidade.

## Matriz obrigatória em aparelho real

Registrar modelo, SoC/GPU, Android, RAM, renderer, perfil, resolução, duração e resultado.

| Área | Procedimento / aceitação |
|---|---|
| Sem microfone | Negar na tela de consentimento; completar fuga por sons internos |
| Permissão negada pelo Android | Permitir no jogo, negar no diálogo do SO; continuar jogável |
| Permissão concedida | Calibração em silêncio, indicador ativo, níveis respondem à voz |
| Revogação | Revogar nas configurações Android; retornar sem crash e sem entrada residual |
| Calibração | Repetir em silêncio, ventilador e TV; registrar piso e falsos positivos |
| Ruídos | Falar baixo, voz normal e voz alta em distâncias fixas da criatura; não é necessário gritar |
| Fones / alto-falante | Medir contaminação pelo áudio do jogo; preferir fones |
| Pausa e foco | Pausar, bloquear tela, alternar app, receber chamada; captura para e não retoma sem continuar |
| Controle imediato | Desligar no HUD; stream para e nível zera |
| Multitouch | Andar + olhar + correr/interagir com três dedos |
| Segurança visual | Parede/porta bloqueia visão; armário oculta, ruído forte pode revelar |
| Navegação | Criatura percorre corredor, entra nas salas e abre portas, sem atravessar paredes |
| Gameplay | Completar fusível → energia → cartão → saída; repetir com derrota e checkpoint |
| Perfil baixo | Sessão de 15 min; medir tempo de frame, quedas, memória e aquecimento; meta 30 FPS |
| Perfil médio/alto | Mesmo percurso e métricas; 60 FPS é objetivo, sem garantia |
| Compatibilidade inferior | Abrir pelo renderer Compatibility em uma cópia do projeto e medir diferenças |

## Pendências de produção
Balanceamento dos limiares com aparelhos reais; cancelamento de eco se necessário; mesh/rig/animações finais; revisão acústica; bake offline de iluminação/navegação; playtest de portas e perseguição; validação completa de acessibilidade, UI em recortes e performance. iOS não foi configurado ou validado.

## Revisão de arte 0.2 — 30/10/2026

69 verificações passaram após integrar GLBs, rig, PBRs, LOD e os anexos. Dez vistas Mobile/Vulkan foram renderizadas na Intel UHD. O microfone físico e o desempenho em aparelho continuam pendentes; nenhum dispositivo ADB estava conectado. Relatório em `OTIMIZACAO_GRAFICA_ANDROID.md`.
