# Áudio da criatura

`tools/art/generate_horror_audio.py` gera 24 WAVs mono PCM16/22.050 Hz, duas variações em cada um dos 12 bancos: patrulha, articulações, arrasto, alerta, investigação, busca, farejo, perseguição, ataque, captura, batida e rangido. Manifesto em `assets/audio/creature_v2` informa duração e pico. O zumbido elétrico contínuo é separado.

São sínteses originais, sem gravações ou vozes de terceiros. Funcionam como identidade sonora inicial; gravação e edição profissionais continuam sendo melhoria possível. Materiais visuais e sons anteriores permanecem disponíveis.

Os Resources em `resources/horror/audio` definem samples, intervalo mínimo, variação de pitch e alcance. `Sound.creature_cue` evita repetição imediata do mesmo sample, respeita cooldown, limita a 24 vozes e toca AudioStreamPlayer3D na posição real da criatura ou objeto. A IA chama bancos ao transitar e periodicamente conforme comportamento. Não há áudio de monstro fantasma em outra sala.

Capturas usam bus Threat; Effects e Music recebem atenuação temporária, restaurada ao liberar a sequência. Volume final respeita configurações. Um breve output_guard reduz autorreativação do microfone; não é cancelamento acústico de eco. Validar em celular real com alto-falante e fones antes de calibrar definitivamente.
