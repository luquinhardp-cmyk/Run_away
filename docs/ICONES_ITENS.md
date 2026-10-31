# Ícones e imagens

15 ícones SVG de ação foram desenhados especificamente para a interface: mochila, lanterna, corrida, agachamento, mão, arremesso, segurar, pausa, microfone, fechar, usar, examinar, descartar, voltar e porta. Não usam emojis e não dependem de serviços externos.

14 thumbnails PNG RGBA 256×256 foram renderizados no Blender 4.5.15. Treze usam os GLBs reais da biblioteca: key, fuse, flashlight, security_card, mechanical_part, can, wrench, bottle, rock, crate, bucket, chair e trolley. A bola de borracha usa a esfera procedural correspondente ao objeto existente, com material worn_rubber. Fundo transparente, enquadramento proporcional e iluminação uniforme de estúdio. A geração liga os mapas albedo/normal/ORM usados pelo projeto aos materiais.

Reprodução: Blender em modo background com `--python tools/art/render_inventory.py`. O script usa Cycles, 24 amostras e a biblioteca existente. As imagens finais ficam em `assets/ui/items/`. Os modelos e texturas originais não são modificados.

Chaves e cartões de treino compartilham a imagem do mesmo modelo real usado na sala. Objetos físicos nas mãos usam o thumbnail correspondente ao perfil. Imagens ficam em cache pelo carregador de recursos; ícones SVG são compartilhados por IndustrialUI.

Itens futuros sem configuração precisam de entrada e imagem próprias; o fallback técnico para IDs desconhecidos não deve ser apresentado como arte final para itens novos.
