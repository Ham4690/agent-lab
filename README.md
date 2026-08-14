# agent-lab
Configurations, skills, and experiments for AI agents & coding assistants

## Setup (apm)

本リポジトリのスキル一式は [apm (Agent Package Manager)](https://github.com/microsoft/apm) パッケージとして `.apm/` 配下に配置。`apm.yml` がマニフェスト。

### apm CLI インストール（初回のみ）

```bash
# macOS/Linux
curl -sSL https://aka.ms/apm-unix | sh

# Windows
irm https://aka.ms/apm-windows | iex
```

### 本リポジトリを任意の場所に clone してセットアップ

```bash
git clone git@github.com:Ham4690/agent-lab.git /path/to/agent-lab

# ユーザースコープ（~/.apm/）へグローバルインストール
apm install -g /path/to/agent-lab

# Claude Code / Codex 双方のユーザースコープ設定を一括生成
# (~/.claude/, ~/.codex/ 配下に skills/agents 等が展開される)
apm compile -g
```

`apm compile -g` は `~/.apm/apm_modules` にグローバルインストール済みのパッケージから、対応する各ツールのユーザースコープ設定ファイルをまとめて生成する。個別ターゲットのみ更新したい場合は `apm compile -t claude` / `apm compile -t codex` をプロジェクトディレクトリ内で実行する。

スキルを追加・変更した場合は `.apm/skills/<name>/SKILL.md` を編集し、再度 `apm install -g /path/to/agent-lab && apm compile -g` を実行すれば反映される。
