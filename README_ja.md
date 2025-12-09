<div align="center"><p><a href="./README.md"><img src="https://img.shields.io/badge/EN-white" alt="version"></a>  <a href="./README_ja.md"><img src="https://img.shields.io/badge/日本語-white" alt="version"></a> </p></div>

# Arm Reference Software Stack for Zena CSS

## 🔒 初めに

このガイドでは以下を説明します：
- 必要なパッケージを含む Docker イメージの作成方法
- Zena CSSソフトウェアスタックを使用した Yocto のビルド
- デモの実行方法

---

## 🧭 概要

Arm Automotive Solutions は親プロジェクトであり、特定世代の Arm Reference Designs を用いて設計・実装可能な代表的な計算サブシステムのリソースを提供することを目的としたものです。

![overview](./picture/overview.png)

以下の子プロジェクト向けの BSP (Board Support Package) が含まれます：
- Kronos Reference Software Stack  
- Zena CSS Reference Software Stack

📢 ビルドホスト要件：
- FVP のビルドと実行には x86_64 または aarch64 ホストが必要
- ダウンロードとビルドのために 300GiB 以上の空きディスク容量
- 32GiB 以上の RAM
- 8GiB 以上のスワップメモリ

---

## 0. 🔶ホストで非特権ユーザー名前空間を有効化する

このリファレンスソフトウェアスタックを実行する前に、ホストマシンで非特権ユーザー名前空間を有効化する必要があります。
以下のコマンドを実行するには、root 権限が必要です。

※ これらの設定はホスト再起動後にリセットされます。
```bash
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
sudo sysctl -w kernel.unprivileged_userns_clone=1
```

## 1. 🐳 Docker イメージの作成

Docker をまだインストールしていない場合は、[インストール手順](https://docs.docker.com/engine/install/) に従って、ビルドホストに `Docker Engine` をインストールしてください。

[`docker_build.sh`](./docker_build.sh) を使用して、提供されている [`Dockerfile`](./Dockerfile) に基づき Docker イメージを作成します。  
このイメージは **Ubuntu 22.04** ベースで、ARM Automotive Software Stack v2.1 開発に必要なパッケージが含まれます。

```bash
./docker_build.sh
```

---

## 2. 🚀 Docker コンテナの実行

[`docker_run.sh`](./docker_run.sh) を使って、作成したイメージから Docker コンテナを起動します。

`-s` フラグを指定することで、ホストのホームディレクトリをコンテナの `/home/docker/share` に共有できます：

- デフォルトログイン: **docker**
- パスワード: **docker**


```bash
./docker_run.sh -s share_folder
```

---

## 3. 🔧 Automotive ARM Software Stack とデモのビルド

コンテナ内に入ると、作業ディレクトリは `/home/docker/arm-auto-solutions` になります。以下が含まれます：

- `sw-ref-stack` フォルダ
- `run_fvp.sh` スクリプト

`sw-ref-stack` は [Arm Automotive Solutions Repository](https://gitlab.arm.com/automotive-and-industrial/arm-auto-solutions/sw-ref-stack) から提供され、**kas** を使った Yocto ビルドの迅速なセットアップが可能です。

ビルドメニューを起動するには：

```bash
kas menu sw-ref-stack/Kconfig
```

（メニュー画面は画像を参照）

![menu](./picture/menu.png)

推奨オプション設定：

- **Platform**: RD-Aspen  
- **Variant**: RD-Aspen MIN  
- **Use-Case**: Arm Automotive Solutions Demo  
- **Stack Architecture**: Baremetal  
- **Primary CPUs**: 4  

⚠️ **Build** を選択すると、ソフトウェアスタックのフルコンパイルが開始されます。このプロセスは**数時間**かかることがあります。

![complete_build](./picture/complete_build.png)

### 📦 YAML レイヤー構成と依存関係

kas の YAML 設定では複数の Yocto レイヤーへの依存関係が定義されています：

```
meta-arm-auto-solutions
├── meta-arm-bsp-extras       # RD-Aspen BSPとパッチ
├── meta-arm                  # Core toolchain & SystemReady DT
├── meta-ewaol                # SOAFEE リファレンスOS
├── meta-security             # セキュアサービス（Parsec, TLS）
├── meta-virtualization       # (オプション for Xen)
├── meta-zephyr               # Safety Island (R82AE) 用ファームウェア
└── poky/meta                 # Yocto ベースシステム
```

各レイヤーは特定の Git URL、ブランチ、リビジョンに固定され、再現性を確保します。

### 🧱 ソフトウェアアーキテクチャ (RD-Aspen)

RD-Aspen は以下の三層構成からなるシステムです：

#### ✅ RSE (Runtime Security Engine)
- Cortex-M55 コア
- TF-M 実行（BL1_1 → BL1_2 → BL2 → ランタイム）
- 提供サービス: セキュアブート、PSA Crypto、Secure Storage、UEFI Variable Storage
- セキュアブートチェーンと認証のエントリーポイント

#### ✅ Safety Island
- Cortex-R82AE コア
- SCP-firmware 実行
- 電源制御やシステム起動シーケンスを担当
- SSU（Safety Status Unit）、FMU（Fault Management Unit）をホスト

#### ✅ Primary Compute
- 最大16コアの Cortex-A720AE
- ブートフロー：
  - TF-A BL2 → BL31
  - OP-TEE BL32
  - U-Boot BL33 → Linux (systemd-boot)
- サポート：
  - Arm SystemReady Devicetree（UEFI+DT）
  - UEFI Secure Boot（RSE支援のPK, KEK, db, dbx）
  - カプセルベースのセキュアファームウェア更新
  - PFDI（障害検出とCLI）
  - PSA API（Crypto, Storage, Attestation）
  - CAM（クリティカルアプリ監視）
  - Linux ディストロ検証：Debian / openSUSE / Fedora

---

## 4. ▶️ Zena CSS FVP 上でソフトウェアスタックを実行

このデモでは **`tmux`** を使ってターミナルセッションを管理します。

以下のコマンドを実行してブートします（数分かかります）：

```bash
tmux new-session -s arm-auto-solutions
./run_fvp.sh
```

- デフォルトユーザー: `root`
- パスワード: *(なし)*

![root login](./picture/login.png)

`ctrl + b` + `w` で tmux のターミナルを切り替えます。

![switch](./picture/switch.png)

### FVP 内のターミナルコンソールマッピング

| **tmux ペイン名**              | **機能** |
|-------------------------------|----------|
| `terminal_uart`               | **RSE** のコンソール。セキュアブート、イメージ認証、セキュアサービス初期化ログを表示。 |
| `terminal_uart_si_cluster0`   | **Safety Island Cluster 0** のコンソール。診断や統合テスト用。 |
| `terminal_sec_uart`           | **AP セキュアワールド**（TF-AやOP-TEE）のコンソール（EL3/EL1S）。 |
| `terminal_ns_uart0`           | **AP 非セキュアワールド**である Linux のコンソール。主なユーザーインターフェース（EL2/EL1N）。 |

各コンソールは FVP 上の異なる処理要素に対応しています。

---

## 🧪 テストの実行

### ✅ Safety Status Unit (SSU)

*準備中*

### ✅ Fault Management Unit (FMU)

*準備中*

---

## 📚 参考資料

- [Arm Automotive Solutions Documentation](https://arm-auto-solutions.docs.arm.com/en/v2.1/index.html)
- [Arm Automotive Solutions Repository](https://gitlab.arm.com/automotive-and-industrial/arm-auto-solutions/sw-ref-stack)
- [Arm Zena Compute Subsystem (CSS) FVP](https://developer.arm.com/Tools%20and%20Software/Fixed%20Virtual%20Platforms/Automotive%20FVPs)
