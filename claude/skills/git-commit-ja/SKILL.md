---
name: git-commit-ja
description: git addされ「ステージ済み」の変更をレビューし、過去のcommit logを確認しながらそのリポジトリの慣習(粒度・文体・prefixルール)に合わせた簡潔な日本語コミットメッセージを作成、自動でcommitまで実行する。ユーザーが「コミットして」「commit message考えて」「これコミットして」「diffからメッセージ作って」などと言った場合、また複数の変更が混在していて粒度調整(分割/統合)が必要そうな場合に必ず使うこと。git addの実行自体はこのskillの責務ではない(下記参照)。
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git commit *)
---

# git-commit-ja

すでにステージされた(`git add`済みの)変更内容と、そのリポジトリの過去のコミット履歴を分析し、日本語で簡潔・的確なコミットメッセージを作成し、最終レビューとユーザーの承認を経てcommitまで実行するためのskill。単にdiffを要約するだけでなく、**粒度(1コミットに詰め込みすぎていないか)の判定と分割提案**、そして**commitの自動実行**まで行う。

## 責務の境界(重要)

`git add` は人間、または前段階の作業(別のLLMセッションや別skill)がすでに済ませている前提とする。このskillは**ステージ済みの内容をレビューし、コミットメッセージを作成し、commitを実行するところまで**に責任を持つ。

- ステージされた変更が無い場合、勝手に `git add` を実行しない。その旨をユーザーに伝え、何をステージすべきか(候補ファイル)を提示するに留める。
- `git commit` の実行はこのskillの責務に含まれる(下記フロントマターの`allowed-tools`もそれに合わせて許可している)。ただし**必ず手順5の最終レビュー・提示・ユーザーの明示的な同意を経てから実行する**。`allowed-tools`は権限プロンプトを省略するだけであり、会話上でユーザーの了承を得る手順を省略してよいわけではない。
- push は行わない。push前の履歴整理は別skill `git-push-ja` の責務。

## いつ使うか

- ステージ済みの変更に対してコミットメッセージが欲しいとき
- ステージされた差分に複数の関心事(機能追加+リファクタ+フォーマット、等)が混在していて分割すべきか判断が要るとき
- 過去のコミットの書き方(Conventional Commitsか、prefixの有無、本文の有無、文体)に合わせたいとき

## 手順

**実行上の注意(全ステップ共通)**: 以下のgitコマンドは `&&` や `;` で連結せず、それぞれ独立したBash呼び出しとして実行すること。`allowed-tools`のprefixマッチは連結されていない単一コマンドにのみ適用され、`cmd1 && cmd2`のような複合コマンドは全体が1つのパターンと一致しない限り確認プロンプトが発生するため(セキュリティ上の仕様)。

### 1. ステージ済みのdiffを取得する

```bash
git status
```
```bash
git diff --staged
```

- 対象は `--staged` のみ。未ステージの変更(`git diff`)は今回のコミット範囲に含めない。
- `git diff --staged` が空の場合は、その旨を伝えて終了する(未ステージの変更があれば「git addされていません」と伝えるだけで、自動でstageしない)。

### 2. 過去のログからそのリポジトリの「作法」を学習する

```bash
git log --oneline -30
```
```bash
git log -10 --stat
```

確認するポイント:

| 観点 | 例 |
|---|---|
| prefix規則 | `feat:` `fix:` のようなConventional Commitsか、`【修正】`のような和式prefixか、prefixなしか |
| 言語 | 日本語/英語/混在 |
| 文体 | 「〜する」体言止めか、「〜しました」敬体か、命令形(Add xxx)か |
| 粒度の実態 | 1コミットあたりの変更ファイル数・行数の傾向(`git log --stat`で把握) |
| 本文(body)の有無 | タイトルのみか、箇条書きの本文まで書いているか |

**過去ログから読み取った作法を優先し、一般的なConventional Commitsルールより実際の慣習に合わせる。** ただしリポジトリに明確な作法がない(ログが少ない/バラバラ)場合は、後述の「デフォルト方針」を使う。

### 3. 変更の性質を分類し、粒度を判定する

diffを見て、変更を以下のようなカテゴリに仕分けする:

- `feat` 新機能・仕様追加
- `fix` バグ修正
- `refactor` 挙動を変えない構造変更
- `style` フォーマット・空白・lint修正のみ
- `test` テストの追加・修正
- `docs` ドキュメントのみ
- `chore` ビルド設定・依存更新など

**分割を提案する基準:**

- 上記カテゴリが2つ以上、かつ互いに独立して意味を成す場合 → 分割を提案
  - 例: 「機能追加」と「無関係なファイルのフォーマット整形」が混ざっている
  - 例: 「バグ修正」と「別issueの新機能」が同じdiffに入っている
- 逆に、以下は同一コミットにまとめて問題ない(分割しない):
  - 実装コードとそれに対応するテスト
  - 実装と、それに伴う設定・型定義・OpenAPIスキーマなどの付随変更
  - 1つの目的のためのリファクタ+実装(段階的リファクタが目的そのものである場合)
- ファイル数が多くても、単一の目的に沿っていれば分割不要。逆にファイル数が少なくても目的が2つあれば分割を検討する。

分割を提案する場合は、`git diff` の内容をもとに「どのhunk/ファイルをどちらのコミットに含めるか」を具体的に提示し、`git add -p` や `git add <file>` の使い分けを案内する。ユーザーが分割を望まない場合は無理に分けず、1コミットのメッセージ内で本文を段落分けして両方の意図を書く。

### 4. コミットメッセージを作成する

**タイトル行:**
- 50文字程度を目安に、変更の「何を」ではなく「何のために/結果何が変わるか」を意識して書く
- 過去ログにprefixの慣習があればそれに従う。無ければデフォルト方針(下記)を使う
- 体言止め or 「〜する」形で統一(過去ログの文体に合わせる)

**本文(必要な場合のみ):**
- 変更が複数ファイル・複数意図にまたがる、または「なぜ」がdiffだけでは自明でない場合に箇条書きで補足
- 単純な1行で説明が済む変更には本文をつけない(過剰な冗長化を避ける)

### デフォルト方針(過去ログに明確な作法がない場合)

Conventional Commits形式をベースに、タイトルは日本語で書く:

```
<type>(<scope>): <変更内容を簡潔に>

- <補足1>
- <補足2>
```

- `<type>`: feat / fix / refactor / style / test / docs / chore
- `<scope>`: 変更した主なモジュール・ディレクトリ名(省略可)
- 本文は変更が自明でない場合のみ

### 5. commit前の最終レビューを行う

実行に移る前に、ステージ済みdiff(手順1で取得済み)を対象に以下を確認する:

- **意図しないファイルの混入**: `.env`, 認証情報、ビルド成果物、`.DS_Store`、一時ファイルなどがステージされていないか
- **デバッグ痕跡**: `console.log`/`print`/`fmt.Println`等のデバッグ出力やコメントアウトされたコード片が残っていないか
- **secrets/認証情報**: APIキー、トークン、パスワードらしき文字列がdiffに含まれていないか

該当する疑いがあれば、commitを実行せずに指摘し、ユーザーに対処(unstageし直す等)を促す。問題が無ければ手順6に進む。

### 6. 提案を提示し、commitを実行する

- 作成したメッセージ(1つ、または分割提案がある場合は複数案)を提示
- 確認なしで`git commit` を実行する
- ユーザーが分割を選んだ場合は、`git add -p` の手順を案内してから該当分のみ commit する
- 明示的な指示がない限り `git push` は実行しない(pushは別skill `git-push-ja` の責務)

## 出力フォーマット例

```
## 最終レビュー
- ステージ済みファイル: 3件、いずれも本来の変更対象で問題なし
- デバッグ痕跡・secrets混入なし

## コミットメッセージ
feat(auth): Bearerトークン検証をpreemptive認証に変更

- HttpRequestInterceptorでchallenge-responseを事前に解決
- 401往復を1回省略し、S3プロキシ経由のレイテンシを削減

```

diffに複数の関心事がある場合は、分割案A/Bとして両方のメッセージ+対象ファイルを提示し、commitする。

## 参考文献

- Conventional Commits 仕様: https://www.conventionalcommits.org/ja/v1.0.0/
- Chris Beams, "How to Write a Git Commit Message": https://cbea.ms/git-commit/
- Google Engineering Practices, "How to Write a CL Description": https://google.github.io/eng-practices/review/developer/cl-descriptions.html
- pro git book (日本語版) 「コミットメッセージ」の章: https://git-scm.com/book/ja/v2
- Angular commit message guidelines(Conventional Commitsの原型): https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md
- Claude Code Skills frontmatter リファレンス: https://code.claude.com/docs/ja/skills#frontmatter-reference
