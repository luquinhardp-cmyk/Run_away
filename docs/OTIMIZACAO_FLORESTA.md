# Floresta

As 736 árvores/arbustos permanecem distribuídas em quatro camadas. Árvores próximas usam a biblioteca Blender com LOD conforme perfil; camadas intermediárias e distantes continuam em MultiMesh e silhuetas de baixo custo. Lua e floresta permanecem no baixo.

Sombras das camadas intermediárias/distantes foram desligadas; árvores próximas conservam sua configuração. Distâncias padrão 70/95/115 m, com opção independente 60/90/115 m. O horizonte contínuo esconde os limites. O terreno irregular e raízes decorativas não aumentam a área navegável, nem bloqueiam rotas existentes.

O estado de área externa é atualizado a cada 0,25 s e compartilhado com o áudio. A criatura alada valida teto ao iniciar; durante o voo usa a região imediata e o estado compartilhado. A condição inicial atualiza esse cache para não cancelar sua própria aparição. A suíte noturna passou após corrigir essa regressão. Não há culling de IA nem remoção de colisores para ganhar FPS.
