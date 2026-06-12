:::header

# RunCat Neo

メニューバーに住む猫。
:::

猫の走る速さが、MacのCPU使用率を教えてくれます。メニューバーをちらっと見るだけで十分です。

![RunCat Neo デモ](./images/demo.gif =480x)

[![App Store でダウンロード](./images/download_on_app_store_ja.svg)](https://apps.apple.com/us/app/runcat-neo/id6757801838)

macOS 26 以降が必要 · [GitHub で見る](https://github.com/runcat-dev/RunCatNeo)

## 特長

~ | [~speed] | [~metrics] | [~light] |
~ | :--- | :--- | :--- |

:::warp speed

### 🐈 ひと目で負荷がわかる

CPU が忙しくなるほど猫は速く走り、落ち着いているときはゆっくり歩きます。数字を読む必要はありません。走る姿を眺めるだけです。
:::

:::warp metrics

### 📊 カスタムメトリクス

ローカルの JSON ファイルを指定するだけで、ダッシュボードのカードになります。CPU やメモリ、そのほか気になる情報を何でも表示できます。
:::

:::warp light

### 🪶 軽量でネイティブ

Swift で最新の macOS 向けに作られています。メニューバーに静かに常駐し、システムリソースをほとんど消費しません。
:::

## カスタムメトリクス

CPU だけでなく、RunCat Neo は自分で用意した JSON ファイルを監視し、カードとして表示できます。ファイルが変化した瞬間に更新され、ポーリングもネットワーク通信もありません。Claude Code の使用状況、GPU 温度、ビットコインの価格、GitHub のコントリビューションなど、ファイルに書き出せるものは何でも表示できます。

- [JSON スキーマリファレンス](https://github.com/runcat-dev/RunCatNeo/blob/main/docs/CustomMetricsSchema.md)
- [Claude Code statusLine サンプル](https://github.com/runcat-dev/RunCatNeo/tree/main/docs/samples/claude-code)
- [ビットコイン価格サンプル](https://github.com/runcat-dev/RunCatNeo/tree/main/docs/samples/bitcoin)

## よくある質問

:::details 走る猫は何を表しているの？
猫の走る速さは、Mac のリアルタイムな CPU 使用率を表しています。システムがアイドル状態のときはゆっくり歩き、高負荷のときは全力疾走します。数字を読まなくても、マシンの忙しさを感覚的につかめる穏やかな方法です。
:::

:::details どうやってインストールするの？
RunCat Neo は Mac App Store で配信されており、macOS 26 以降が必要です。[こちらからダウンロード](https://apps.apple.com/us/app/runcat-neo/id6757801838)できます。
:::

:::details 対応している言語は？
RunCat Neo は次の 10 言語に対応しています。英語、日本語、中国語（簡体字）、中国語（繁体字）、韓国語、フランス語、ドイツ語、スペイン語、ロシア語、ベトナム語。
:::

:::details カスタムメトリクスとは？
カスタムメトリクスとは、[所定の形式](https://github.com/runcat-dev/RunCatNeo/blob/main/docs/CustomMetricsSchema.md)で書かれたローカルの JSON ファイルのことです。小さなスクリプトでファイルを最新の状態に保つと、RunCat がファイルシステムのイベントで監視し、変化した瞬間にカードとして表示します。まずは[すぐに使えるサンプル](https://github.com/runcat-dev/RunCatNeo/tree/main/docs/samples)から始めてみてください。
:::

:::details 既存の RunCat と同じもの？
いいえ。RunCat Neo は、最新の macOS 向けに新しく作られた次世代の RunCat です。既存の RunCat の置き換えやアップグレードではなく、コンセプトを新たに捉え直したものです。
:::

:::details バグ報告や機能リクエストはどこで？
[GitHub リポジトリ](https://github.com/runcat-dev/RunCatNeo)でテンプレートに従って Issue を作成してください。開発者同士の議論には、[RunCat Developers コミュニティ](https://runcat-dev.github.io)をご利用ください。
:::

:::footer
[プライバシーポリシー](./privacy_policy.html?lang=ja) · [GitHub](https://github.com/runcat-dev/RunCatNeo) · [RunCat Developers](https://runcat-dev.github.io)

[English](./) · **日本語**

© 2026 Takuto Nakamura (Kyome22)
:::
