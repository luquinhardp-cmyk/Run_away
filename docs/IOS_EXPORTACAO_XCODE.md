# Exportação Xcode

No Mac, instalar Xcode e Godot 4.7.2 com templates correspondentes. Abrir o projeto, selecionar preset iOS e preencher `application/app_store_team_id` (10 caracteres) e `application/bundle_identifier` registrado pelo proprietário. Não alterar o identificador Android.

Exportar para pasta nova `builds/ios/`, nome ECOS sem espaços, com `application/export_project_only=true`. Abrir o projeto gerado no Xcode, selecionar equipe e configurar assinatura/provisionamento. Compilar e instalar primeiro em aparelho de teste. Depois criar Archive, validar e enviar ao App Store Connect/TestFlight conforme os requisitos vigentes da conta.

Não foi exportado projeto Xcode neste Windows nem assinado IPA. O preset é preparação; não é comprovação de aprovação Apple. Antes do envio, revisar ícones, versão/build, declarações de privacidade do Firebase, dispositivos e metadados. Futuras atualizações devem preservar o Bundle Identifier definido na primeira distribuição e aumentar o build.

[Exportação oficial Godot](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html).
