# Áudio da floresta e entidade

`tools/art/generate_night_assets.py` sintetiza 14 WAV mono PCM16/22.050 Hz em `assets/audio/night`: três gritos, três asas, três deslocamentos de ar e cinco ambientes (vento, folhas, insetos, galho, animal distante). Originais algorítmicos, sem gravação de filmes/jogos ou dependência de licença externa. Manifesto acompanha arquivos. Gritos combinam frequências graves/agudas, modulação, ruído e eco curto; não equivalem a uma sessão profissional de foley.

Evento tem três AudioStreamPlayer3D presos à entidade. Volume nominal de grito próximo -17 dB e distante -23 dB; asas/ar -21/-29 dB. Distância máxima 170 m, atenuação inversa, filtros passa-baixas 8 kHz perto e 2,6 kHz longe. Variação de sample/pitch, sem repetir sample imediato. Deslocamento de ar ocorre na passagem próxima. Sem áudio no padrão `moon_silent`; `silent` preserva só asas. `unseen_cry` apaga a silhueta antes de vocalizar.

`forest_audio.gd` reutiliza três vozes, posicionadas entre árvores reais, alcance 48 m, volume -27 dB. Intervalos 12–26 s, pausa ocasional 10–22 s e ausência de repetição imediata do banco. Áudio abaixa dentro dos prédios e durante evento/captura. O loop exterior antigo de RuralArt foi removido para evitar sobreposição; ambiência interna anterior permanece.

Buses FlyingNear/FlyingDistant enviam a Effects e respeitam o volume existente. Mic.output_guard evita o breve início reproduzido; não é cancelamento acústico contínuo. Use fones para testar microfone. Atenuação/limites/silêncio foram verificados por automação; equilíbrio perceptivo, direção em aparelhos e microfone físico continuam pendentes.
