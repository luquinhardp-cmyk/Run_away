# Regressão Android/iOS

Android mantém package `org.ecos.instalacaoabandonada`, versão/code 9, assinatura e preset anteriores. Esta etapa não distribui APK novo nem modifica certificado. Atualização futura exige code maior e verificação por `tools/verify_android_update.py`.

As alterações compartilhadas foram exercitadas nas suítes headless e no benchmark Web indicado em `WEB_TESTES_REGRESSAO.md`. Nenhum aparelho Android ou Apple foi usado nesta etapa. Portanto, regressão nativa de dispositivo permanece pendente.

Antes da próxima distribuição, validar APK instalado por cima da versão anterior, dados preservados, microfone, multitouch, retorno do segundo plano, captura e uma fuga completa. No iOS, repetir após primeira compilação e assinatura no Mac. Manter os links públicos já definidos.
