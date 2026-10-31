# Endereços permanentes

Solicitação do usuário: manter os mesmos links em todas as atualizações.

- Jogo: https://run-away-ecos.pages.dev/
- Jogo direto: https://run-away-ecos.pages.dev/play/
- APK atual: https://run-away-ecos.pages.dev/baixar-apk

Publicar a versão validada no deployment de produção do projeto Cloudflare Pages `run-away-ecos`. URLs de branches/builds servem para diagnóstico e histórico, não substituem o endereço entregue ao jogador. A partir da solicitação de link fixo, a versão de produção acompanha a versão publicada, inclusive quando ela é explicitamente uma prévia técnica com pendências artísticas.

`hosting/prepare.py` gera o redirecionamento temporário `/baixar-apk` para o APK da versão, normaliza o botão de download da página inicial e registra o endereço permanente nos metadados. O APK versionado do GitHub permanece como histórico. Na próxima atualização, mudar o destino gerado, preservando as URLs acima.

Manter identificador Android, certificado e versionCode crescente para substituir a instalação. A URL fixa não instala silenciosamente: o usuário ainda confirma a atualização no Android.
