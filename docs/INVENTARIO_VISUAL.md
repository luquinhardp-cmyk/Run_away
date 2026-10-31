# Mochila real

`scripts/ui/inventory_catalog.gd` fornece somente apresentação de IDs existentes. `inventory_window.gd` lê `Game.inventory`, `Game.world.throwables` e o objeto efetivamente segurado. Não há lista de itens fictícios concedidos ao abrir a UI. Quantidades e salvamento continuam nos sistemas originais.

Grade com imagens, nomes, quantidades, indicador textual ESSENCIAL e seleção. Categorias aparecem somente se houver itens correspondentes. A ordenação é visual e não modifica IDs ou dados. Game.updated atualiza a janela; ela não é reconstruída a cada frame.

| Ação | Comportamento |
| --- | --- |
| Usar | Disponível perto do mecanismo compatível sob a mira; chama a interação real após fechar a UI |
| Equipar | Liga a lanterna existente ou seleciona a sucata para arremesso |
| Examinar | Um modelo low em SubViewport sob demanda; perfil baixo usa imagem ampliada |
| Descartar | Disponível para sucata ou objeto nas mãos; cria/solta um corpo físico, sem apagar silenciosamente |
| Fechar | Despausa, restaura controles e mantém o inventário real |

Itens de missão, lanterna e chave não podem ser descartados. O callback também valida essa proteção, além de desabilitar o botão. A sucata é decrementada somente se houver espaço e a criação do corpo for permitida. O impacto posterior pode produzir ruído de gameplay normal.

Inspeção tem arraste para girar, roda/+ e − para zoom e VOLTAR. Há um único viewport de 512×384; ele é removido ao sair da inspeção e renderiza novamente apenas quando necessário. Não foram criados viewports individuais por slot. [Inspeção](review/tutorial-ui/inspection.png).
