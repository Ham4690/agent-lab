---
name: git-push-ja
description: 前回のpushから現在までのローカルコミット群を確認し、過去のcommit logの粒度感に照らして「まとめる/並べ替える/書き直す」べきかを判断したうえでpushする。ユーザーが「push して」「まとめてpushしたい」「pushする前に整理して」「ここまでの作業をまとめてpushして」などと言った場合に必ず使うこと。git-commit-jaが1コミット単位の粒度を扱うのに対し、こちらは「未push区間全体」の粒度・順序を扱う。
allowed-tools: Bash(git log *) Bash(git fetch *) Bash(git rev-parse *) Bash(git merge-base *) Bash(git status *)
---

# git-push-ja

前回pushしてから今までに積まれたローカルコミット群を見て、push前に「これは1つのまとまりとして意味が通るか」を整理し直してからpushするためのskill。git-commit-jaが「1コミットぶんのステージ内容」を対象にするのに対し、このskillは「複数コミットにまたがる未push区間」を対象にする。

## 責務の境界(重要)

- `git add` / 個々のコミット作成は行わない(それぞれ人間の作業や `git-commit-ja` の責務)。
- 対象はあくまで **まだリモートに反映されていない区間** のみ。すでにpush済みでリモートに存在する履歴は書き換えない。
- 保護されたブランチ(`main` / `master` / `develop` など、他者と共有され直push運用が前提のブランチ)では、履歴の書き換え(rebase)は行わず、素直に `git push` するのみに留める。整理が必要でも提案に留め、実行はユーザーに委ねる。

## 手順

### 1. 現在のブランチと前回pushの位置を特定する

```bash
git rev-parse --abbrev-ref HEAD
git fetch origin
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
```

- upstream(`@{u}`)が無ければ、そのブランチはまだ一度もpushされていない。この場合「前回push」は存在しないので、ブランチの起点(例: `main`との分岐点 `git merge-base HEAD origin/main`)からHEADまでを対象区間とする。
- upstreamがあれば `origin/<branch>..HEAD` が未push区間になる。

### 2. 未push区間のコミット一覧を確認する

```bash
git log --oneline @{u}..HEAD      # upstreamがある場合
git log --stat @{u}..HEAD         # 各コミットの変更規模も見る
```

- 保護ブランチ判定: 対象ブランチ名が `main`/`master`/`develop`/`release/*` 等、あるいは直push禁止がCI設定等から読み取れる場合は「保護ブランチモード」とし、手順4の履歴整理はスキップして手順6の確認済みpushのみ行う。

### 3. 過去のcommit logの粒度感を学習する(git-commit-jaと同じ観点)

```bash
git log --oneline -30 @{u}
```

- このブランチ/リポジトリでは1つのpushあたり・1コミットあたりどの程度の粒度が普通か(例: 1機能=1コミットにまとめる文化か、細かい作業コミットをそのまま残す文化か)を把握する。

### 4. 未push区間を評価し、整理案を作る

各コミットのメッセージとdiffを見て、以下を判定する:

- **squash対象**: `wip`, `fix typo`, `oops`, `修正`, `一時保存` のような、単体では意味を持たない作業コミットが直後に続いている → 直前の論理コミットに `squash`/`fixup` する
- **reword対象**: 内容は適切だがメッセージが雑(`update`, `てすと` 等)→ git-commit-jaと同じ基準でメッセージを書き直す(`reword`)
- **reorder対象**: 依存関係のない変更が離れて並んでいて読みにくい場合、意味のまとまりで並べ替える
- **分割対象**: 1コミットに独立した複数の関心事が混在している → これは自動実行せず、「`git rebase -i` で該当コミットをeditに変え、手動でsplitしてください」と手順を案内するに留める(自動分割はしない)
- 上記のいずれにも該当せず、既に粒度が適切なら「整理不要、このままpushして良い」と結論づける

整理が必要な場合は、実行前に **interactive rebase の todo 案**を提示してユーザーの確認を取る:

```
pick a1b2c3d feat: 認証まわりの基盤実装
fixup e4f5g6h wip
pick h7i8j9k feat: ログイン画面のUI追加
reword k0l1m2n てすと直した   → "test: ログインフォームのバリデーションテスト追加"
```

### 5. 承認を得てから実行する

ユーザーが整理案を承認した場合のみ実行する:

```bash
git rebase -i <base-commit>
```

(自動化する場合は `GIT_SEQUENCE_EDITOR` 等でtodoを事前生成してから実行してもよいが、実行前に必ず最終的なtodo内容をユーザーに見せること)

- **注意**: この区間がまだ一度もpushされていない(upstreamが無い、または `@{u}..HEAD` が対象)場合、rebaseは安全。
- **注意**: 過去に一度この未push区間の一部を既にpush済みで、今回さらに書き換える場合(force-pushが必要なケース)は、必ずその旨をユーザーに明示し、明示的な同意を得てから `git push --force-with-lease` を使う。保護ブランチでは絶対にforce-pushしない。

### 6. push する

```bash
git push origin <branch>
```

- 履歴を書き換えた場合で、かつリモートに同名ブランチの旧履歴が既に存在する場合のみ `--force-with-lease` を使う(通常の初回push・fast-forward可能な場合は不要)。
- 保護ブランチの場合、手順4をスキップしているので通常の `git push` のみ実行する。
- push前に必ず最終的なコミット一覧(`git log --oneline @{u}..HEAD` 相当)を再表示し、ユーザーに最終確認を取ってから実行する。

## 出力フォーマット例

```
## 未push区間の確認 (origin/feature-x..HEAD)

1. a1b2c3d feat: 認証まわりの基盤実装
2. e4f5g6h wip
3. h7i8j9k feat: ログイン画面のUI追加
4. k0l1m2n てすと直した

## 整理提案
- 2 は 1 に fixup(単体で意味を持たない作業コミットのため)
- 4 は reword: "test: ログインフォームのバリデーションテスト追加"
- 分割が必要な混在コミットは無し

この内容でrebaseしてよろしいですか?(このブランチはまだpush済みではないので安全に書き換え可能です)
```

## 参考文献

- Pro Git, "Rewriting History"(rebase -iの解説): https://git-scm.com/book/ja/v2/Git-%E3%81%AE%E3%81%95%E3%81%BE%E3%81%96%E3%81%BE%E3%81%AA%E3%83%84%E3%83%BC%E3%83%AB-%E6%AD%B4%E5%8F%B2%E3%81%AE%E6%9B%B8%E3%81%8D%E6%8F%9B%E3%81%88
- git-rebase 公式マニュアル(squash/fixup/reword/editの違い): https://git-scm.com/docs/git-rebase
- GitHub Docs, "About force pushes"(force-with-leaseの安全性): https://docs.github.com/en/get-started/using-git/dealing-with-non-fast-forward-errors
- Google Engineering Practices, "How to Write a CL Description"(1つの変更として意味が通る単位について): https://google.github.io/eng-practices/review/developer/cl-descriptions.html
- Claude Code Skills frontmatter リファレンス: https://code.claude.com/docs/ja/skills#frontmatter-reference
