# Manipulação e mecanismos

No computador, mire a até 2,5 m: mantenha R para segurar um objeto leve ou arrastar um médio. Solte R para largar; Q arremessa o leve e apenas solta o médio. E oferece alternativa de pegar/largar por toque ou empurra os móveis. No touchscreen, mantenha SEGURAR/ARRASTAR; use ARREMESSAR/SOLTAR enquanto mantém o outro dedo. Olhar e joystick continuam independentes.

O controlador `scripts/physics/manipulator.gd` aplica uma mola amortecida por força, com alvo a 1,35 m da câmera, massa máxima 3 kg e força limitada a 45 N. Arrasto de categoria C aceita até 20 kg, limita a 95 N e força vertical zero. Não congela, desativa colisão ou escreve posições para acompanhar a câmera. Usa varredura esférica conservadora do volume para restringir alvo diante de paredes e outros objetos. Libera se distância exceder 2,5 m ou se ficar preso por mais de 0,8 s. Pausa, esconderijo, derrota e saída liberam o objeto.

Arremesso aplica impulso dependente da massa, com velocidade pretendida limitada a 8 m/s, rotação e CCD. O inventário original de peças também usa o novo PhysicalProp3D e continua limitado a oito arremessáveis temporários, com limpeza em 20 segundos. Objetos já existentes na sala não geram cópias ao serem lançados.

`character_push.gd` transforma contatos do move_and_slide em impulsos limitados para jogador/criatura. A criatura pode deslocar pequenos obstáculos e mantém a navegação original; corpos dinâmicos não entram no bake estático. Não usa teleporte para atravessar itens. Máquina ancorada continua bloqueando os personagens.

Portas: `mechanism.gd` cria folha AnimatableBody3D, pivô na borda, limite de 90°, abertura de 0,65 s ou lenta de 1,6 s pelo diretor. Colisão da folha permanece no percurso; consulta de forma impede esmagar atores e atravessar objetos. Se houver bloqueio, espera desobstrução. Fechamento ainda recusa passagem ocupada. Trancas, energia, chave, estado e navegação anteriores foram preservados. Transformação atômica evita perder o pivô com sync_to_physics. Não são portas livres com HingeJoint.

Gaveta: movimento linear de 36 cm com fundo/laterais/frente reais, colisões e som, estado persistente. A ferramenta interna é um corpo físico independente e o bilhete é decoração legível pela mensagem de interação. O gabinete tem tampo e laterais fixos. O movimento controlado empurra objetos leves pela física nativa; detecção antecipada protege os personagens. Objetos presos podem bloquear ou deslocar conteúdos, sem abertura instantânea.

Corrente: links instanciados, balanço amortecido com limite de 0,45 rad, interação e sensor de impactos, retorno ao repouso e som posterior ao contato inicial. É um pêndulo controlado, não 12 corpos/juntas. Cabos secundários continuam estáticos; não há cordas físicas caras em toda a instalação.
