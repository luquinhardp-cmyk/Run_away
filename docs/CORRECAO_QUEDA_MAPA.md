# Queda nas laterais da entrada

O relato do usuário foi reproduzido por sondagem física: o pátio começava em z=2, mas a fachada terminava em x=2 e x=-10. As faixas laterais entre z=0 e z=2 tinham aparência de chão/terra, sem piso físico; as cercas laterais também começavam em z=2. Era possível caminhar para fora do apoio ao lado da porta.

Em `scripts/systems/facility.gd`, foram adicionados somente os dois ombros de piso correspondentes, com 9×2 m e 1×2 m, materiais visíveis e colisores BoxShape3D na camada 1. Cercas de retorno fecham a passagem atrás deles. As extensões laterais visíveis têm 1,3 m, preservando a abertura da janela da enfermaria. `facility_art.gd` continua os postes e trilhos até a entrada. Não há piso de resgate gigante sob o cenário.

Antes: 15 de 42 sondagens da entrada sem apoio. Depois: 42/42 com apoio. Outras 158 sondagens cobriram centros/cantos dos módulos, rampa e subsolo, sem ausência de chão. A inspeção estrutural encontrou 253 CollisionShape3D na camada do mundo, sem shapes nulas, desativadas ou determinantes negativos. O cenário efetivo é complexo industrial, pátio, rampa/subsolo e tutorial; não há mapas separados de estrada/casa ou carregamento por setores a auditar nesta versão. A floresta distante é cenário além das cercas, sem promessa de exploração livre.

`scripts/player/fall_recovery.gd`, anexado ao jogador, amostra posições a cada 0,35 s somente com apoio estático, normal adequada e cápsula livre. Cinco sondagens verificam também o apoio ao redor dos pés: o topo estreito de uma cerca não pode virar destino seguro. Conserva até 12 posições recentes e verifica novamente cada destino. Abaixo de -8 m, ou após queda superior a 4 s e 6 m de desnível, tenta a posição recente e depois o spawn conhecido, também validado. O subsolo a aproximadamente -1,8 m continua acessível. Sequências de captura, esconderijos, pausa e o jogador com metadata `legitimate_fall` durante uma queda narrativa não acionam resgate.

O resgate zera velocidades e controles de toque, solta o objeto manipulado, restaura a câmera e avisa no HUD. Não altera itens, objetivos ou checkpoint. Há cooldown de 3 s e limite de três recuperações em 15 s. Sem destino válido ou com repetições anormais, a sessão pausa e o jogador fica fisicamente parado mesmo se continuar: deve reiniciar pelo menu. Nunca teleporta para uma posição não verificada.

## Diagnóstico local

`user://fall_incidents.json` guarda até 64 incidentes: data UTC, cena, posição observada, início da queda, última posição segura, velocidade, duração, máscara de colisão, destino e causa provável. A causa é heurística, não uma conclusão automática sobre a geometria. O arquivo não contém voz e não é enviado ao Firebase. Na Web, fica no filesystem persistente da engine, apoiado pelo IndexedDB `/userfs`; nas versões nativas, na pasta de dados do aplicativo.

Evidências: [antes](review/stability/before-map.json), [depois](review/stability/after-map.json), `tests/stability_runner.tscn`, `tests/geometry_runner.tscn` e [validação](review/stability/validation.json). Foram testados movimento real em ambos os sentidos, corrida/agachamento, objeto físico caindo no trecho corrigido, rampa e recuperação forçada. Não substitui exploração manual de todos os centímetros em aparelhos reais.
