# Preparação iOS

Mesma base Godot/GDScript, sem nova IA ou substituição Android. Preset iOS ARM64 separado para iPhone e iPad, mínimo configurado iOS 14 e exportação de projeto Xcode. Safe area do HUD agora inclui iOS e tamanho atual do canvas.

Preparação não equivale a aplicativo iOS compilado. Ambiente disponível é Windows; não há Xcode, dispositivo Apple ou assinatura. Team ID e Bundle Identifier estão vazios intencionalmente: precisam ser os da conta Apple do proprietário. Nenhum IPA foi gerado.

Renderer Mobile continua nativo. O simulador iOS só aceita Compatibility segundo a documentação do Godot; uma medição no simulador não valida o renderer Mobile do aparelho.

[Requisitos oficiais](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html).
