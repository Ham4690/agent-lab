# agent-lab
Configurations, skills, and experiments for AI agents & coding assistants

## Setup Claude Skills

全スキルを `~/.claude/skills/` にシンボリックリンク登録。既存 link は skip、新規 skill は自動追加。

スクリプト自身の位置から skill ソースを解決 → clone 先・実行 cwd 問わず動作。

```bash
# repo root から
bash claude/scripts/setup-skills.sh

# 任意の場所から（パス指定すればどこでも可）
bash /path/to/agent-lab/claude/scripts/setup-skills.sh
```

動作：
- `claude/skills/` 配下の全ディレクトリをスキャン
- 既に正しく link されていれば skip
- 古い/違う link は削除して再作成
- 新規スキルは自動登録
