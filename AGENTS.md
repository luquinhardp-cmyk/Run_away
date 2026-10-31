# Preferências persistentes de publicação

Quando publicar uma atualização autorizada, mantenha os mesmos endereços entregues ao usuário:

- Jogo: https://run-away-ecos.pages.dev/
- Jogo direto: https://run-away-ecos.pages.dev/play/
- Download do APK atual: https://run-away-ecos.pages.dev/baixar-apk

O usuário pediu explicitamente para não trocar o link a cada atualização. Não substitua esses endereços por aliases de branches ou hashes de deployment na entrega. Links de preview podem ser adicionais para diagnóstico.

Cloudflare Pages: projeto `run-away-ecos`; branch de produção configurada `feature/base-survival-horror-3d`. A branch Git de implementação pode ser diferente. `hosting/prepare.py` gera o redirecionamento temporário de APK para o artefato versionado. Confira a versão no endereço canônico depois do deployment.

Android: preservar `org.ecos.instalacaoabandonada`, o certificado de assinatura existente e aumentar versionCode para permitir atualização sobre a instalação anterior. Não versionar chaves privadas. Verificar compatibilidade com `tools/verify_android_update.py`.
