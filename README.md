# agent-lab
Configurations, skills, and experiments for AI agents & coding assistants

## Setup Claude Skills

全スキルを `~/.claude/skills/` にシンボリックリンク登録。既存 link は skip、新規 skill は自動追加。

```bash
bash ~/workspace/agent-lab/claude/scripts/setup-skills.sh
```

動作：
- `claude/skills/` 配下の全ディレクトリをスキャン
- 既に正しく link されていれば skip
- 古い/違う link は削除して再作成
- 新規スキルは自動登録
