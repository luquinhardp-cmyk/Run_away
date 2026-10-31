# Contas e progresso — 0.3

Atualização 0.4: o checkpoint v2 também guarda seed, dificuldade, instalação do painel, atalhos, eventos e consumo de peças. Saves v1 continuam aceitos. Para testar esse progresso entre aparelhos, use 0.4 em ambos: o cliente antigo desconhece os novos campos. Veja `OBJETIVOS_E_ENIGMAS.md` e `RELATORIO_EXPANSAO.md`.

Cloudflare Pages hospeda o jogo Web: https://run-away-ecos.pages.dev/. Firebase `run-away-f63e4` fornece Authentication (e-mail/senha) e Firestore, região `southamerica-east1`. Não usa Functions nem precisa de Identity Platform pago. O Web app registrado tem configuração pública em `resources/firebase_config.json`; essa chave identifica o cliente, não concede acesso administrativo.

No menu, abra **CONTA / PROGRESSO**, crie uma conta ou entre. Use a mesma conta em outro aparelho e escolha continuar. Sem login, o jogo funciona com saves locais. Senhas e tokens não são gravados em arquivo: é necessário entrar novamente ao reabrir o aplicativo. A recuperação de senha usa o e-mail da conta.

## Dados

- `players/{uid}`: totais de pontos, partidas, fugas, melhor tempo e checkpoint.
- `players/{uid}/runs/{id}`: resultado imutável, tempo ativo, pontos, itens e energia daquela tentativa. IDs aleatórios de 128 bits permitem repetir envios sem duplicar pontos.
- Checkpoint: inventário, energia, portas e tempo acumulado. Retomar posiciona o jogador na enfermaria segura. Uma tentativa retomada recebe outro ID e inclui o tempo anterior; não retoma a posição do monstro.
- Pontos: 100 por item único, 300 por restaurar energia, 500 por escapar. Máximo 1.100 por tentativa. Apenas tentativas encerradas somam pontos; derrotas preservam pontos de objetivos atingidos. Melhor tempo considera fugas.
- O cronômetro exclui pausas e o menu. Saves ocorrem ao coletar, restaurar energia, pausar, voltar ao menu e a cada 15 segundos de jogo ativo.

O envio de resultado e o incremento dos totais acontecem num commit atômico. O melhor tempo usa mínimo no servidor. Reenvio reconhece um resultado idêntico já salvo, inclusive quando as regras recusam a recriação. Renovação de ID token usa refresh token apenas em memória.

## Sem conexão e conflitos

Cada UID tem seu próprio diretório local `user://accounts/{uid}/`, incluindo checkpoint, histórico e `outbox.json`. A fila é persistida antes da tentativa de envio e volta a sincronizar ao entrar na mesma conta. Ela não é enviada sob outra conta. Totais mostrados na conta são os confirmados pelo servidor; partidas pendentes têm contador separado.

Ao entrar ou atualizar, checkpoints diferentes entre uma fila local e o servidor exigem escolher qual manter. Resultados concluídos são independentes dessa escolha. Durante uma sessão já conectada, o último checkpoint enviado substitui o anterior; evite jogar simultaneamente na mesma conta em dois aparelhos. O botão de importar visitante substitui explicitamente o checkpoint da conta e não importa pontos. Progresso local pode ser perdido se o navegador limpar os dados do site ou o aplicativo for desinstalado antes de sincronizar.

## Regras e validação

`firestore.rules` permite acesso somente ao dono autenticado. Resultados não podem ser editados ou apagados pelo cliente. Totais só mudam junto de um resultado novo com pontuação coerente. Todos os demais caminhos são negados. Tempos e objetivos são reportados pelo cliente; os dados servem para progresso pessoal e não constituem ranking competitivo protegido contra adulteração do cliente.

Deploy das regras:

```powershell
firebase deploy --only firestore:rules --project run-away-f63e4
```

`tests/cloud_runner.tscn` é uma suíte **online explícita**: cria duas contas temporárias `runaway-qa-…@example.com`, testa isolamento, salvamento, reenvio, renovação, conflitos, fila persistente, pontuação e pausa. Exclui as contas ao terminar. O responsável pela execução deve limpar seus documentos de teste usando acesso administrativo, com os UIDs gravados no arquivo indicado por `RUN_AWAY_TEST_USERS`. Não executar em paralelo com o jogo. A suíte normal `tests/runner.tscn` não acessa contas nem grava resultados.

Android tem permissão de Internet; a Web usa HTTPS e a mesma API REST diretamente da Godot. Nenhuma voz é enviada ao Firebase.

Validação desta entrega: 69 verificações do jogo e 17 testes online passaram. As contas temporárias e seus documentos foram removidos após os testes. APK 0.3.0 ARM64 exportado e assinatura v2/v3 verificada. Isso não substitui testes em celulares físicos.
