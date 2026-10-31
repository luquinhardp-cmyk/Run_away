# Atualização Android e captura — ECOS 0.8

O APK usa o mesmo identificador `org.ecos.instalacaoabandonada`, nome ECOS e chave de assinatura do APK anterior. A versão passa de 0.7.0/código 7 para 0.8.0/código 8. O Android pode substituir a instalação existente e preservar seus dados ao abrir o APK e confirmar **Atualizar**. Não é instalação automática: a confirmação pertence ao instalador do Android.

A comparação dos APKs exportados passou também contra a versão 0.3.0/código 3: mesmo identificador e certificado SHA-256 em ambos os casos. Evidências em `review/performance/android_update.json` e `android_update_oldest.json`. O certificado público pode ser registrado; a chave privada não entra no repositório.

Não desinstale o aplicativo antes de atualizar. Aplicativos de versões históricas com outro identificador são instalações independentes; não é possível removê-los silenciosamente pelo novo APK. Perfis de trabalho, usuários diferentes e funções de clonagem do aparelho também mantêm instalações separadas.

`tools/verify_android_update.py APK_ANTERIOR APK_NOVO --output docs/review/performance/android_update.json` verifica assinatura válida, mesmo pacote, mesmo certificado e código crescente. Execute antes de cada distribuição. Preserve a chave de assinatura fora do Git e com backup seguro: trocar de chave impede a atualização normal. Esta prévia ainda usa a chave de depuração existente; mudar para uma chave de distribuição exige planejar a migração, sem prometer compatibilidade automática.

## Jumpscare

Contato válido continua sendo obrigatório: a captura não alcança o jogador através de paredes nem à distância. Durante a derrota, a câmera aproxima-se pela frente do rosto animado a cerca de 80 cm, estreita o FOV para 42° e aponta para o centro do rosto. Uma luz local breve revela o rosto, sem estrobo. O jogador físico permanece parado; um raycast evita mover a câmera através de paredes. Ao encerrar ou cancelar, posição, rotação e FOV são restaurados.

O grito usa o banco original de captura, com ganho maior, prioridade entre as vozes, atenuação próxima e teto de -6 dB no emissor. Os demais sons são reduzidos pelo mix existente durante a captura. Os volumes mestre/efeitos e os ajustes de intensidade, movimento de câmera e sustos visuais continuam funcionando. Com movimento desativado, o zoom também fica desativado. Não existe medição de volume acústico em aparelho físico nesta entrega.

Arquivos: `scripts/horror/capture_sequence.gd`, `scripts/audio/sound.gd`, `export_presets.cfg`, `tests/horror_runner.gd`, `tests/capture_review.gd` e o verificador de APK. A suíte de horror contém 29 verificações aprovadas, incluindo foco, distância, FOV, áudio, imobilização, restauração e acessibilidade. A imagem `review/performance/capture_closeup.png` registra a revisão visual nativa. O resultado da comparação de APKs fica em `review/performance/android_update.json`; instalação real com dados existentes permanece pendente sem aparelho conectado.
