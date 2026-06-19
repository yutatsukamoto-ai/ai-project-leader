# Claude Code実環境検証 指示書（2026-06-19）

目的: Codexで実装済みのHooks/CI基盤を、Claude Codeの実ランタイムで検証し、M-05/WI-08の残作業を抜け漏れなく閉じる。

対象コミット:

- `8829b7b feat: Hooks/CI基盤を実装`

この指示書はClaude Codeに渡すための作業指示。Codexの擬似stdinテストでは確認できない、Claude Code本体でのHook発火・subagent読み込み・Stop prompt挙動を実地で確認する。

---

## 0. 最初に読むもの

作業前に以下を読む。

1. `CLAUDE.md`
2. `AGENTS.md`
3. `README.md`
4. `プロジェクト骨子.md`
5. `00_プロジェクト管理/構造レビュー/懸念マスター.md`
6. `00_プロジェクト管理/CC版_実装仕様書.md`
7. `00_プロジェクト管理/Hooks_CI_インストール仕様書_for_Codex.md`
8. `00_プロジェクト管理/Claude_Code版を作るときの覚書_モデル堅牢性.md`

必要なら公式ドキュメントも確認する。2026-06-19時点でCodex側では以下を参照済み。

- Hooks: `https://code.claude.com/docs/en/hooks`
- Subagents: `https://code.claude.com/docs/en/sub-agents`

---

## 1. 今回の作業スコープ

やることは次の5つ。

1. **WI-08: Claude Code実環境検証**
2. **正典の状態更新**
3. **`.claude/settings.local.json` の影響切り分け**
4. **CIへのHook/Claude Code配布スモーク追加**
5. **CC版仕様書の旧サンプル同期**

やらないこと:

- 3案件目の実証には進まない。WI-08が終わってから。
- W-02（監視push化）には着手しない。M-05/WI-08が閉じてから。
- 既存の未コミット変更を勝手に戻さない。
- `.claude/settings.local.json` を削除・上書きしない。切り分けのために一時退避が必要なら、ユーザー確認を取る。
- 実案件データや `30_Flow/実案件/` を配布物・Stockへ移さない。

---

## 2. 既知の注意点

Codex作業後の時点で、以下の未コミット変更が残っている可能性がある。今回の作業に関係しないものは触らない。

- `AGENTS.md`
- `CODEX.md`
- `00_プロジェクト管理/CC版_実装仕様書.md`
- `00_プロジェクト管理/Claude_Code版を作るときの覚書_モデル堅牢性.md`
- `00_プロジェクト管理/構造レビュー/懸念マスター.md`
- `30_Flow/テスト/Skillテスト_image2-brand-slides/sales_cubs_consulting_sample/`

`.claude/settings.local.json` はローカルには存在する可能性があるが、gitignore対象。配布版には含めない。

---

## 3. 事前確認

まず状態を確認する。

```bash
git status --short
git log --oneline -5
git check-ignore -v .claude/settings.local.json .claude/skills/anken-rikai-summary/SKILL.md _dist || true
```

期待:

- `8829b7b feat: Hooks/CI基盤を実装` が履歴にある
- `.claude/settings.local.json` はignore対象
- `.claude/skills/` と `_dist/` はignore対象

次にローカル検証を流す。

```bash
bash _tools/test-hooks.sh
bash _tools/build.sh --verify
bash _tools/build.sh --check
bash _tools/package-dist.sh --target claude-code
bash _tools/test-dist-cc.sh
```

期待:

- `test-hooks.sh`: `PASS=25 FAIL=0 TOTAL=25`
- `build.sh --verify`: 異常なし
- `build.sh --check`: ドリフト0
- Claude Code配布スモーク: PASS

ここで失敗したら、実環境検証へ進まず原因を修正する。

---

## 4. WI-08 実環境検証

### 4.1 Hook設定がClaude Codeに読み込まれるか

Claude Codeセッション内で `.claude/settings.json` が有効になっていることを確認する。

確認対象:

- `PreToolUse`: `gate-check.sh`
- `PostToolUse`: `auto-build.sh` → `auto-eval.sh`
- `TaskCompleted`: `auto-eval.sh`
- `Stop`: prompt hook

合格条件:

- Claude Codeの実セッションで各Hookが登録されていることが確認できる
- もしClaude Code側のUI/ログで確認できない場合は、実動作テストで代替する

### 4.2 PreToolUse: gate-check.sh

テスト用フォルダを使い、承認記録なしで次フェーズへ書き込もうとしてdenyされることを確認する。

推奨テスト:

1. `30_Flow/テスト/Hook検証_YYYYMMDD/01_立ち上げ/test.md` へのWriteをClaude Codeに依頼
2. `00_前段/計画提案書_test.md` に `## 承認記録` がない状態ではdenyされることを確認
3. `00_前段/計画提案書_test.md` に `## 承認記録` を作成してから再実行し、allowされることを確認

合格条件:

- deny理由がClaude Codeに伝わる
- 承認記録追加後は通る
- `20_Skills/` や通常開発ファイルへの書き込みはdenyされない

注意:

- テスト用ファイルは `30_Flow/テスト/Hook検証_YYYYMMDD/` に閉じる
- 実案件フォルダでは試さない

### 4.3 PostToolUse: auto-build.sh

正典ファイルまたはSkill本体編集後に自動処理が走ることを確認する。

安全な確認方法:

1. 実ファイルを壊す編集はしない
2. まず擬似入力テスト済みであることを確認
3. 実環境で試す場合は、テスト用Skillまたは影響のないコメント修正で行う

確認観点:

- `20_Skills/*/*/SKILL.md` 編集時に対象Skillのbuildが走る
- `sync-manifest.tsv` の左辺にある正典編集時に `build.sh --sync` が走る
- 成功時は余計な出力を出さず、失敗時のみ `additionalContext` が出る

合格条件:

- `/tmp/claude-hooks-build.log` に実行ログが残る
- 失敗時だけClaudeに追加文脈が返る

### 4.4 PostToolUse / TaskCompleted: auto-eval.sh

30_Flow配下のMarkdown成果物書き込み時にevalが走り、TaskCompletedでは過剰実行しないことを確認する。

確認観点:

- `30_Flow/**/*.md` へのWrite/Edit後にevalが走る
- `20_Skills/` へのWrite/Editでは走らない
- TaskCompletedは、前回eval以降に新しいMarkdown更新がある場合のみ走る
- `/tmp/claude-hooks-eval-<project_key>.stamp` により毎回evalが走り続けない

合格条件:

- `/tmp/claude-hooks-eval.log` に実行ログが残る
- 連続でTaskCompletedが起きても、更新がなければ2回目以降は空振りする
- eval失敗時は `additionalContext` でClaudeに伝わる

### 4.5 Stop prompt hook

まとまりのあるタスク完了時だけチェックポイント・ルーチンが発火するか確認する。

確認観点:

- Hook検証タスク完了後に、必要なら「何が片付いたか」「宿題」「衛生作業」「次の一手」が提示される
- 単なる小編集ごとに毎回うるさく発火しない
- 直前応答がすでにチェックポイント・ルーティンなら再発火しない

合格条件:

- 形骸化していない
- うるさすぎる場合は、条件文を調整する案を出して止まる

### 4.6 Subagents

`.claude/agents/` の4本がClaude Codeに認識されるか確認する。

対象:

- `eval-judge`
- `researcher`
- `integrity-checker`
- `status-aggregator`

確認方法:

- Claude Codeの `/agents` または実セッション内の呼び出しで存在確認
- 可能なら `@agent-eval-judge` のような明示呼び出しで1件だけ軽く動かす

合格条件:

- 4本が表示・呼び出し可能
- `model` / `maxTurns` / `tools` が定義どおり読まれている

---

## 5. `.claude/settings.local.json` の影響切り分け

ローカルには `.claude/settings.local.json` が存在する可能性がある。このファイルはgitignore対象で、配布版には含めない。

やること:

1. 内容を読み、何の許可が入っているか記録する
2. 実環境検証結果が `settings.local.json` の許可に依存していないか確認する
3. 依存していそうな場合は、ユーザーに確認して一時退避または `_dist/` 側でのクリーン検証を行う

合格条件:

- 「ローカル許可があるから通っただけ」ではないと説明できる
- 切り分け不能なら、残リスクとして正典に記録する

---

## 6. 正典更新

実環境検証後、必要な正典を更新する。

必須更新:

1. `00_プロジェクト管理/構造レビュー/懸念マスター.md`
   - `test-hooks.sh=22` を `PASS=25 FAIL=0 TOTAL=25` に修正
   - `install-hooks.sh実行` という記述を、実態に合わせて修正
   - WI-08の実環境検証結果を追記
   - M-05を `✅解決済み` にできるか判断。Claude Code実環境で主要Hookが通れば解決済みにしてよい

2. `00_プロジェクト管理/構造レビュー/決定の索引.md`
   - 「Hooks強制はCC版の宿題」表現を、実装済み/実環境検証済みの状態へ更新
   - 未決欄からM-05を外すか、残があれば具体化する

3. `00_プロジェクト管理/CC版_実装仕様書.md`
   - WI-02/WI-04の旧サンプルを現行実装に同期
   - Phase 5の結果を記録
   - `install-hooks.sh` が存在しないなら該当表現を削除または修正

任意更新:

- `00_プロジェクト管理/Hooks_CI_インストール仕様書_for_Codex.md`
  - 「settings.local.json は存在しない」を「配布対象外。ローカルにある場合は影響切り分け」と修正

---

## 7. CI追加

`.github/workflows/ci.yml` にHook/Claude Code配布スモークを追加する。

現状:

```yaml
- bash _tools/build.sh --verify
- bash _tools/eval.sh
```

追加候補:

```yaml
- name: Hook scripts smoke test
  run: bash _tools/test-hooks.sh

- name: Claude Code distribution smoke test
  run: |
    bash _tools/package-dist.sh --target claude-code
    bash _tools/test-dist-cc.sh
```

合格条件:

- GitHub Actions上で通る
- `_dist/` はgit追跡されない
- 配布スモークで `CLAUDE.md` が含まれ、`AGENTS.md` / `CODEX.md` が含まれないことを確認できる

---

## 8. 検証コマンド

変更後、最低限これを流す。

```bash
bash _tools/test-hooks.sh
bash _tools/build.sh --verify
bash _tools/build.sh --check
bash _tools/eval.sh
bash _tools/package-dist.sh --target claude-code
bash _tools/test-dist-cc.sh
```

CIを変更した場合、可能ならローカルでYAML構文も確認する。

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci.yml"); puts "ci.yml OK"'
```

rubyが無ければこの確認はスキップしてよい。

---

## 9. 完了条件

完了とみなす条件:

- `bash _tools/test-hooks.sh` が `PASS=25 FAIL=0 TOTAL=25`
- `build.sh --verify` / `--check` / `eval.sh` がPASS
- Claude Code実環境で `gate-check.sh` のdeny/allowを確認済み
- Claude Code実環境で `auto-build.sh` / `auto-eval.sh` のログまたは挙動を確認済み
- Stop prompt hookが形骸化していないと判断できる
- subagent 4本がClaude Codeに認識される
- `settings.local.json` の影響を説明できる
- 正典3点（懸念マスター・決定の索引・CC版実装仕様書）が更新済み
- CIにHook/CC配布スモークが追加済み
- 関連変更だけをcommit済み

推奨コミットメッセージ:

```bash
git commit -m "test: Claude Code実環境でHooks基盤を検証"
```

またはCI変更を分けるなら:

```bash
git commit -m "ci: HookとClaude Code配布スモークを追加"
```

---

## 10. 完了後の次の一手

WI-08が完了したら、次は以下の順。

1. W-02（監視フェーズ能動サジェストpush化）をやるか判断
2. 3案件目を新入力形式（議事録/スライド）で回す
3. 実証で必要になった厚みSkillだけをプルで作る

ただし、3案件目へ進む前にユーザー確認を取る。
