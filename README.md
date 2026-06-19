# GitHub Actions + Linux + Ollama + Gemma 朝食テスト

GitHub-hosted Linux runner上でUbuntuコンテナーをビルドし、Ollamaをインストールして `ollama run gemma4:e2b` を実行します。卵を使った朝食メニューの回答は、Actionsログ、Job Summary、7日間保存されるartifactへ出力されます。

## 実行方法

`main` へのpushで自動実行されます。または **Actions > Ollama Gemma breakfast test > Run workflow** から手動実行できます。

`gemma4:e2b` のモデル層は約7.16 GB（Q4_K_M、5.1B）で、Ollama 0.20.0以上が必要です。標準GitHub-hosted runner向けに6 GBのswapを追加し、コンテキスト長を1024、並列数を1に抑えています。
