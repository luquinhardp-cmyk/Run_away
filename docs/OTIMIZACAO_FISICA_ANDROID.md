# Física mobile e limites

A fase usa 12 corpos dinâmicos persistentes, em vez de transformar toda a decoração em rigid bodies. Gerenciador permite no máximo 16 props autorais e inventário limita a oito arremessáveis temporários: teto normal de criação de 24 corpos por esses caminhos. Fixtures de teste podem ultrapassar esse número deliberadamente. `maximum_awake` orienta sleeping de corpos praticamente parados; não congela arbitrariamente um corpo em queda.

Objetos inativos usam sleeping nativo. Perfil baixo congela apenas dois props secundários distantes, já praticamente imóveis; reativa ao aproximar ou mudar o perfil. Objetivos essenciais não dependem disso. Corrente distante não atualiza balanço no baixo. Médio/alto mantêm a mesma física essencial para evitar diferença injusta entre aparelhos.

CCD em props rápidos, formas primitivas e compostas pequenas, até oito contatos por corpo, ruídos por limiar/cooldown e máximo compartilhado de 24 vozes. Snapshot físico roda a cada dois segundos, gerência de distância a cada meio segundo. Materiais e samples são compartilhados. Não há pooling de 24 corpos persistentes: o custo/complexidade não trouxe benefício nesta escala. Fragmentos são visuais e limitados a 12, removidos em oito segundos.

Decoração fina continua agrupada por material e região. Novos mapas de props são 256/128. Portas/gavetas usam corpos controlados, corrente usa instancing e pêndulo; não há cadeias de juntas físicas em cada cabo.

`tests/physics_runner.tscn` valida quedas, repouso, atrito, impulso, CCD, limites de massa/força, parede, arrasto, gaveta, balanço, impacto, audição, queda de 12 corpos, passagem da criatura e restauração. Testes de regressão e fase completa complementam. Resultados e métricas de renderização ficam no relatório e em `docs/review/physics`.

Nenhum Android físico foi usado. Exportação e assinatura de APK não medem FPS. Pendentes: FPS sustentado nos três perfis, memória real, aquecimento, bateria, latência de áudio, microfone/eco, gesto com múltiplos dedos, retomada de foco e comportamento do solver sob FPS baixo. Capturas desktop e valores Performance.MEMORY_STATIC não equivalem ao consumo total de RAM do telefone.
