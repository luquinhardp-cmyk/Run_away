# Capturas e eventos de susto

`capture_sequence.gd` pertence à criatura existente. Oito Resources em `resources/horror/captures` descrevem frente, lado, costas, esconderijo, corredor, corrida, silêncio e escuro. Pesos só concorrem quando o contexto é compatível. A última variante fica em Game entre reinícios de fase na mesma execução, evitando repetição quando existem alternativas.

A derrota exige contato próximo e visão real, ou aproximação ao esconderijo com ocupante confirmado. Durante o ataque a IA revalida visão e distância. A sequência tem dono único, bloqueia movimentos/interações, suspende microfone e toca o clipe configurado. Sem contato válido, não sequestra controles. Paredes continuam bloqueando percepção. Não teleporta jogador nem criatura.

Câmera olha gradualmente para a cabeça real com pequeno deslocamento e rotação limitados; intensidade depende de scares, camera_motion e visual_scares. Com movimento zero e efeitos desativados, mantém a câmera. Áudio entra a 18% do clipe; derrota conclui após a duração do Resource. Pausa congela progresso; saída libera bloqueio e mixagem. Captura de armário revela o esconderijo real, usando abertura visual provisória do conjunto, sem porta articulada independente.

Eventos ambientais são independentes da captura, moderados pelo HorrorDirector. Microfone não dispara jumpscare automaticamente. Não há estroboscopia. As fotos capture_* documentam poses; não equivalem a teste completo de cada encontro em aparelho físico.
