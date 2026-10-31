# Auditoria de desempenho — 0.8

Projeto existente preservado: Godot 4.7.2; Mobile no Android e Compatibility na Web. Viewport de referência 1280×720, stretch de interface `canvas_items`. A cena principal cria a instalação por código. Há iluminação local, materiais PBR, floresta instanciada e duas apresentações de criatura; somente a terrestre mantém IA de perseguição.

Antes: resolução interna 65/85/100% por perfil, sem MSAA; parte das texturas sem mipmaps; a identificação de céu aberto era repetida pelo áudio ambiental a cada frame e novamente durante voos. A previsão navegável de perseguição era projetada a cada tick físico. Física continua a 60 Hz, colisores simples, objetos com repouso e CCD seletivo. O microfone é RMS/gate local, sem envio de áudio ao Firebase. Login e checkpoint não mudaram de formato.

Agora: `Graphics` centraliza perfis e opções, mipmaps e filtragem foram corrigidos, consultas externas usam o estado calculado a cada 0,25 s, e a projeção de perseguição acompanha o sensor existente. Não foram removidos sentidos, estados, colisões ou objetivos. Há sombras da lanterna no médio e sombras lunares no alto; isso aumenta o custo gráfico e impede atribuir toda diferença a otimizações.

Medição: `tests/performance_review.tscn`, Intel UHD/Compatibility, 1280×720, VSync desligado, FPS sem limite **somente no benchmark**. Dez cenários medem tempo de frame/p95, CPU, física, GPU, IA, memória, render e consultas. Arquivos em `review/performance/`. RMS simulado não valida microfone real. Amostra de exploração de 60 s não valida temperatura/bateria nem sessão prolongada Android. Mais detalhes em [comparativo](COMPARATIVO_DESEMPENHO.md).
