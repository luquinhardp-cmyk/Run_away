# Otimização e validação Android

Renderer Compatibility, LOD principal 11.144 e baixo 5.126 triângulos; materiais/texturas acompanham perfil existente. Rebites usam MultiMesh. Detalhes das salas usam o agrupamento estático existente. Letras têm distância de leitura. Novos sons são mono; Sound limita vozes e cooldown. Diretor avalia seleção a cada 0,5 segundo, sem procurar caminho adicional a cada quadro. Presença não adiciona luz no perfil baixo.

Exportação Android ARM64, versão 0.5.0/código 5, permissões INTERNET e RECORD_AUDIO. APK de testes usa assinatura debug; não é release de loja. Web usa WebGL 2 e mantém login/salvamento Firebase. Modelos Blender e GLBs antigos ficam fora do pacote novo.

Revisão desktop: `tests/horror_review.tscn`, imagens e métricas em `docs/review/horror`. Os números de chamadas e primitivas são capturas no desktop Intel UHD, não benchmark de FPS no Android. Testes de lógica headless também não medem desempenho mobile.

Não havia dispositivo Android conectado. Permanecem pendentes em hardware real: permissão e nível do microfone, eco dos alto-falantes, latência de áudio, memória, FPS sustentado, temperatura, bateria e ergonomia touch. Testar perfis baixo/médio, movimento de câmera zero, efeitos visuais desativados, pausa durante captura, rotação e troca de foco. Conta Firebase deve recuperar checkpoint e pontos em um segundo aparelho.
