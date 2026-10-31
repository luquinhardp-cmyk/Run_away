# Floresta densa

`scripts/environment/dark_forest.gd` gera 736 árvores/arbustos em MultiMesh, com três geometrias reutilizadas: árvore morta ramificada, copa larga e pinheiro. Escala, rotação e posição variam por semente. Materiais reutilizam madeira podre e chão de folhas existentes; copas usam `shaders/forest_wind.gdshader`, com vento lento sem física de folhas.

Camadas: 64 árvores próximas em oito setores; 576 intermediárias em dois anéis; 40 árvores enquadrando o pátio; 56 arbustos junto às cercas. Uma malha contínua de horizonte fecha 360 graus, com copas distantes e culling por setor. Há seis troncos caídos e 42 colisores cilíndricos simplificados. Árvores nascem no solo externo y=0; o terreno visual mantém abertura sobre instalação, rampa e porão. Nenhum colisor foi colocado sobre as rotas jogáveis de fuga.

O jogador continua limitado pelo cercamento preexistente. Arbustos e troncos ajudam a explicar seus limites; a floresta não é um novo mapa explorável. O piso visual externo não adiciona chão sobre o porão. Neblina de profundidade oculta gradualmente a camada distante. Não há volumetria, simulação individual de raízes/folhas ou vegetação destrutível.

Baixo mantém árvores próximas, arbustos e horizonte e reduz intermediárias a 42%; médio 72%; alto 100%. Distâncias intermediárias: 70/95/115 m. Ver `OTIMIZACAO_AMBIENTE_ANDROID.md`. Cobertura e silhuetas foram examinadas em capturas do pátio; os modelos usam geometrias simples, ainda passíveis de refinamento artístico.
