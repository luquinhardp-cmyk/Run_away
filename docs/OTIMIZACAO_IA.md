# IA e microfone

A criatura mantém visão, ruído, memória, navegação, procura, esconderijos, perseguição e ataque. A previsão de posição na perseguição guarda o ponto projetado no mapa de navegação até a próxima atualização do sensor existente, aproximadamente 0,18 s. Trocar para perseguição invalida o cache. O movimento físico continua em todos os ticks, sem diminuir a frequência dos sentidos.

O áudio ambiental deixa de lançar um teste de teto a cada frame. Durante a aparição alada, também não há repetição por frame da consulta de teto; checagens de captura, perseguição e limite externo continuam imediatas.

O microfone acumula o tempo dos frames aguardando 256 amostras antes de atualizar calibração/gate. Isso evita que o relógio de detecção dependa da taxa de renderização. Timeout de silêncio usa tempo real sem contar duas vezes a espera. Mantidos consentimento, calibração, ruído de fundo, cooldown, proteção contra retorno do próprio jogo e suspensão na captura/pausa.

Regressões gerais e de expansão executam sentidos, distrações, procura e fuga completa. RMS sintético do benchmark informa apenas custo de cálculo; calibração acústica, grito real do jogador e latência de microfone Android não foram validados fisicamente.
