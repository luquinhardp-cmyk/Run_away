# Placas físicas

`scripts/world/world_sign_3d.gd` e `scenes/world/world_sign_3d.tscn` oferecem painel com espessura, quatro rebites instanciados, material PBR e texto aplicado na frente. Não usam billboard, renderização sobre paredes ou verso legível. O HUD continua independente.

Propriedades: sign_id, text, sign_type, dimensions, wear, illuminated, language, reading_distance, post_mounted e surface. A rotação pertence ao Node3D. O desgaste altera cor, rugosidade e tinta; language identifica o conteúdo escrito pelo autor, sem tradução automática. Tipos: metal, wood, emergency, danger, map e paper.

`facility.gd::_label` monta a sinalização de orientação nos batentes e paredes existentes. `facility_art.gd::_room_stories` acrescenta avisos da enfermaria, manutenção, depósito, mapa físico da segurança e instruções elétricas. Postes sustentam a sinalização externa. Distância de leitura limita o custo dos textos; os painéis permanecem visíveis um pouco além.

Textos continuam sendo Label3D sobre painéis reais, com teste de profundidade e face única. Não são texturas rasterizadas; isso permite editar o conteúdo sem recriar imagens. Inspecionar alinhamento após alterar paredes ou dimensões. Fotos em `docs/review/horror`.
