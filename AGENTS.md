# AGENTS.md - AI Agent 向けリポジトリガイド

このドキュメントは AI Agent（Cursor Agent 等）がこのリポジトリを理解するためのガイドです。

## 概要

このリポジトリは [chezmoi](https://www.chezmoi.io/) を使用した dotfiles 管理リポジトリです。
chezmoi はホームディレクトリの設定ファイル（dotfiles）をバージョン管理し、複数マシン間で同期するためのツールです。

### 所有者情報

- GitHub ユーザー: BoomKunLab
- 主な使用環境: WSL2 (Linux) + Windows

## chezmoi の命名規則

chezmoi はファイル名のプレフィックス/サフィックスで特殊な処理を行います：

| プレフィックス/サフィックス | 変換結果 | 例 |
|---|---|---|
| `dot_` | `.` に変換 | `dot_bashrc` → `.bashrc` |
| `symlink_` | シンボリックリンクとして作成 | `symlink_dot_chezmoi` → `.chezmoi` (symlink) |
| `.tmpl` | テンプレートとして処理 | `dot_Brewfile.tmpl` → `.Brewfile` |
| `private_` | パーミッション 0600 で作成 | - |
| `.disabled` | 無視される（適用されない） | `100_starship.zsh.disabled` |

## ディレクトリ構造

```
.
├── .chezmoiexternals/    # 外部リソース定義（Git リポジトリ等から取得）
├── .chezmoiscripts/      # chezmoi apply 時に実行されるスクリプト
├── dot_bashrc            # → ~/.bashrc
├── dot_zshrc             # → ~/.zshrc
├── dot_gitconfig         # → ~/.gitconfig
├── dot_Brewfile.tmpl     # → ~/.Brewfile (テンプレート)
├── dot_config/           # → ~/.config/
│   ├── mise/             # mise (バージョン管理) 設定
│   └── starship/         # Starship (プロンプト) 設定
├── dot_shellrc.d/        # → ~/.shellrc.d/ (シェル設定スクリプト群)
├── dot_windows/          # Windows 用設定ファイル
└── symlink_dot_*         # ホームディレクトリへのシンボリックリンク
```

## シェル設定の仕組み

### 読み込みフロー

1. シェル起動時に `~/.bashrc` または `~/.zshrc` が読み込まれる
2. これらのファイルは `~/.shellrc.d/` 配下のスクリプトを自動読み込みする
   - bash: `*.sh` と `*.bash` ファイル
   - zsh: `*.sh` と `*.zsh` ファイル
3. ファイルは名前でソートされて順番に読み込まれる

### dot_shellrc.d/ の命名規則

```
{優先度}_{機能名}.{シェル種別}[.disabled]
```

- **優先度（数字）**: 小さい数字が先に読み込まれる
  - `010_*`: 基本設定（エイリアス、環境変数、シェルオプション）
  - `100_*`: ツール初期化（mise, starship, nushell）
  - `200_*`: 言語/アプリケーション固有設定（Go, kubectl）
- **シェル種別**:
  - `.sh`: bash/zsh 両方で読み込まれる
  - `.bash`: bash のみ
  - `.zsh`: zsh のみ
- **`.disabled` サフィックス**: 無効化されたファイル（読み込まれない）

### 現在有効なスクリプト

| ファイル | 役割 |
|---|---|
| `010_aliases.sh` | ls, grep 等の基本エイリアス |
| `010_brew.sh` | Homebrew 初期化 |
| `010_environment.sh` | 環境変数、PATH 設定 |
| `010_git_util.zsh` | Git ユーティリティ関数 |
| `010_shopt.bash` | bash シェルオプション |
| `010_vscode_integration.*` | VS Code ターミナル統合 |
| `100_mise.*` | mise（バージョン管理）初期化 |
| `100_nu.*` | Nushell 初期化 |
| `100_starship.bash` | Starship プロンプト初期化 |
| `200_go.sh` | Go 言語環境設定 |
| `200_kubectl_util.*` | kubectl ユーティリティ |

## 使用ツール

このリポジトリで管理されている主要ツール：

- **chezmoi**: dotfiles 管理
- **mise**: 言語バージョン管理（asdf 代替）
- **Starship**: クロスシェルプロンプト
- **Homebrew**: パッケージ管理
- **ghq**: Git リポジトリ管理
- **fzf / peco**: ファジーファインダー
- **eza**: モダンな ls 代替
- **Nushell**: モダンシェル

## 編集時の注意事項

### ファイル追加時

1. chezmoi の命名規則に従う
2. シェルスクリプトは適切な優先度番号を付ける
3. bash/zsh 両対応の場合は `.sh` 拡張子を使用
4. テンプレートが必要な場合は `.tmpl` サフィックスを追加

### 無効化/有効化

- ファイルを無効化: `.disabled` サフィックスを追加
- ファイルを有効化: `.disabled` サフィックスを削除

### テスト

```bash
# 変更を確認（dry-run）
chezmoi diff

# 変更を適用
chezmoi apply

# 特定ファイルのみ適用
chezmoi apply ~/.bashrc
```

## よくある操作

```bash
# chezmoi ソースディレクトリに移動
chezmoi cd

# 現在のファイルと管理ファイルの差分を確認
chezmoi diff

# 外部ファイルを取り込む
chezmoi add ~/.some_config

# テンプレートとして追加
chezmoi add --template ~/.some_config
```
