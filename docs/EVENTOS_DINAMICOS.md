# Eventos dinâmicos

`events.gd` é filho da fase, sem singleton. `HorrorEvent` Resources em `resources/world/` definem ID, tipo, área, probabilidade, cooldown, prioridade e persistência. Eventos elegíveis são avaliados por prioridade, com no máximo um disparo por atualização. O sorteio usa seed/ID/janela de cooldown; estados persistentes vivem no checkpoint. O sinal `triggered(id)` permite outros consumidores.

| Evento | Gatilho e consequência |
|---|---|
| impact | Primeira passagem ao sul de z=-12: ruído real na lata do depósito; atmosférico |
| pipe | Passado o intervalo do perfil e jogador ao sul de z=-16: tubulação física ocupa parte do corredor e atualiza navegação; lateral permanece livre |
| blackout | Energia ativa pelo intervalo do perfil: apaga luzes principais, bloqueia dispositivos elétricos ainda fechados e ativa alarme |

Todos os eventos entregues são únicos por partida, mesmo ao retomar. O apagão não remove fusível nem instalação: basta retornar e acionar o gerador. Portas já abertas e caminhos manuais permanecem utilizáveis. A oscilação antiga de lâmpada foi mantida com redução suave, sem flashes rápidos.

Nova sessão aceita seed numérica nas configurações; zero usa uma seed automática. A variante inverte a patrulha e escolhe uma de duas posições acessíveis do fusível dentro da manutenção. Seed, dificuldade e eventos são salvos para reprodução. A dificuldade da sessão não muda ao alterar o seletor durante uma partida: vale para a próxima nova sessão.
