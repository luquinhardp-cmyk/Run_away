# Céu e lua de sangue

Implementação 0.7 na branch `feature/blood-moon-dark-forest`. Auditoria anterior: [AUDITORIA_CEU_FLORESTA.md](AUDITORIA_CEU_FLORESTA.md).

`scripts/environment/night_world.gd` reaproveita o WorldEnvironment da instalação. `shaders/blood_moon.gdshader` desenha céu azul-preto, estrelas esparsas com intensidades e tamanhos variados e disco lunar de aproximadamente 12 graus. A direção mundial normalizada `(0.15, 0.70, 0.70)` permanece fixa ao mover o jogador. O disco pertence ao Sky: não existe esfera próxima, colisão ou paralaxe lunar. A geometria do mundo o encobre normalmente.

`assets/textures/night/moon_craters.png` contém crateras e manchas geradas por `tools/art/generate_night_assets.py`, sem material externo. O shader acrescenta relevo aparente, borda irregular e halo controlado. Não há objetos individuais para estrelas, ciclo solar ou animação celeste. Sky usa processamento automático e radiância de 32 pixels; reflexão de céu desabilitada. O shader permanece idêntico nos três perfis.

DirectionalLight3D vermelho com energia 0.055; sombras somente no alto, alcance 32 m. Ao sair, luz ambiente transita de 0.38 para 0.075; interiores preservam a energia anterior. A exposição/tonemapping Filmic existente foi preservada. Os valores do céu foram ajustados por captura real no Compatibility para evitar esmagamento total das estrelas no preto.

Verificação: importação sem erro, capturas `review/night/01_moon.png`, `03_shadow_moon.png` e `quality_0..2.png`. Lua visível, oclusão pelas árvores e estrelas verificadas visualmente. Ainda requer avaliação de brilho em telas físicas diferentes; a arte é procedural e estilizada, sem alegação de fotorealismo.
