# Codex指示: git commit & push

前回の `Codex実行指示_2026-06-17.md` の全7項目が完了済み。
Cowork側で実ファイル検証済み（grep/build/eval全通過）。
これをGitHubに反映する。

---

## 手順

### 1. push前ゲート

```bash
bash _tools/build.sh --verify
bash _tools/eval.sh
bash _tools/build.sh --release-check
```

3つとも異常なしを確認してから進む。
`--release-check` でTODOが出た場合は報告して止める。

### 2. 差分確認

```bash
git status
git diff --stat
```

想定される変更:

**脱識別（6ファイル）**
- `00_プロジェクト管理/構造レビュー/懸念マスター.md`
- `00_プロジェクト管理/構造レビュー/決定の索引.md`
- `00_プロジェクト管理/構造レビュー/履歴/構造レビュー_命名・層の揃え_2026-06-15.md`
- `00_プロジェクト管理/この時点でやるべきこと棚卸し_2026-06-15_v2.md`
- `00_プロジェクト管理/履歴/この時点でやるべきこと棚卸し_2026-06-15.md`
- `00_プロジェクト管理/GitHub公開前_対応指示書_2026-06-17.md`

**golden追加（8成果物 + goldens.tsv）**
- `_tools/eval/goldens.tsv`
- `30_Flow/2026-06-16/模擬案件_丸山製作所/02_計画/05〜09_*_v0.1.md`
- `30_Flow/2026-06-16/模擬案件_丸山製作所/03_実行/03〜04_*_v0.1.md`
- `30_Flow/2026-06-15/模擬案件_スマートファクトリー_設備稼働IoT/05_終結/02_PoC評価報告書_v0.1.md`

**slide-craft移動**
- `90_横断/skills/slide-craft/` → 削除
- `20_Skills/90_横断/slide-craft/` → 新規（SKILL.md + references/）
- `20_Skills/成果物マップ.md` → slide-craft行追加 + 旧v3 TODO削除
- `20_Skills/90_横断/README.md` → slide-craft追記
- `_tools/package-dist.sh` → コピー対象整理

**管理ドキュメント（新規）**
- `00_プロジェクト管理/Codex実行指示_2026-06-17.md`
- `00_プロジェクト管理/移動案_slide-craft配置.md`
- `00_プロジェクト管理/Codex指示_git-push_2026-06-17.md`（この文書自体）

**README.md** → slide-craft関連の更新があれば

### 3. 配布除外の最終確認

```bash
# .gitignoreで除外されるべきものが混入していないか
git status | grep -E '\.skill|_dist/|_backups/|\.claude/skills|50_サンプル成果物'
```

何もヒットしないこと。

### 4. commit & push

```bash
git add -A
git status  # 最終確認

git commit -m "fix: 脱識別・eval補強・構造整理

- 管理文書6件から実社名を匿名化（A方式・最新コミット修正）
- golden 8件追加（計46件、テスト可能な全24 Skillカバー）
- slide-craftを20_Skills/90_横断/に統一、旧90_横断/削除
- 成果物マップの旧v3未統合TODOを決着・削除
- build --verify 34/34同期・異常なし / eval 46/46 PASS"

git push origin main
```

### 5. push後確認

```bash
git log --oneline -1
git diff HEAD~1 --stat
```

---

## やらないこと

- サンプル成果物整理（別枠）
- Git履歴の書き換え（A方式＝最新コミットのみ）
- .skill ファイルのpush（.gitignore対象）
