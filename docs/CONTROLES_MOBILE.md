# Controles mobile

Paisagem, viewport de referência 1280 × 720, CanvasItems escalável. HUD mostra objetivo, prompt central, microfone, joystick e seis ações. Área esquerda controla movimento; direita controla câmera. IDs de dedos independentes permitem andar e olhar simultaneamente enquanto um terceiro dedo aciona botões.

Os botões recebem input GUI; o detector de áreas de olhar/mover exclui seus retângulos. CORRER alterna o estado para permitir corrida sem manter o dedo sobre um botão. Agachar também alterna. Pausar zera dedos e corrida. Joystick tem zona de arrasto flutuante a partir do toque e indicador fixo no HUD.

Configurações persistentes: sensibilidade, FOV, tamanho 80–130%, opacidade, deslocamento horizontal e vertical. Área segura Android é consultada e convertida a coordenadas do layout; verificação em telas com recorte é pendente. Posições são ajustadas em conjunto por lado, sem editor de arrasto individual.

## Teste em aparelho
Andar + olhar + correr, soltar um dos dedos sem cancelar o outro, interagir em movimento, abrir pausa com dedos pressionados, retomar sem movimento residual, rotação/orientação bloqueada em paisagem, resoluções 16:9 e 20:9, recorte à esquerda e direita. Medir tamanho físico dos botões: o alvo de 76 pixels de referência deve permanecer confortável no aparelho escolhido.

O teste automatizado injeta dois eventos de toque e verifica IDs independentes; não substitui testes reais de gesto e latência.
