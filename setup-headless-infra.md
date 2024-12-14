# **Resonite ヘッドレスサーバのインフラを構築する**

## **主な作業**
本チュートリアルでは Resonite ヘッドレスサーバを載せる GCE インスタンスが稼働するネットワークを構築します

下記を構築、設定します

- `VPC ネットワーク`
- `ネットワークファイアウォール`

## **インフラ構築用の環境を作成する**

右側の `Cloud Shell` へコピーするボタンをクリックし、ターミナルで Enter を押してください

インフラ構築用の環境変数を読み込みます
```bash
source ~/resonite-headless-infra/scripts/env-headless-server.bash
```

環境変数が設定されたことを確認します
```bash
echo -e "RESONITE_HEADLESS_ENVIRONMENT=${RESONITE_HEADLESS_ENVIRONMENT}" \\n "VPC_NAME=${VPC_NAME}" \\n "SUBNET_NAME=${SUBNET_NAME}" \\n "REGION=${REGION}" \\n "SUBNET_RANGE=${SUBNET_RANGE}" \\n "RESONITE_HEADLESS_SERVER_INSTANCE_NAME=${RESONITE_HEADLESS_SERVER_INSTANCE_NAME}" \\n "IMAGE_PROJECT=${IMAGE_PROJECT}" \\n "IMAGE_FAMILY_SCOPE=${IMAGE_FAMILY_SCOPE}" \\n "IMAGE_FAMILY=${IMAGE_FAMILY}" \\n "ZONE=${ZONE}" \\n "SETUP_RESONITE_HEADLESS_SERVER_SCRIPT=${SETUP_RESONITE_HEADLESS_SERVER_SCRIPT}" \n "MACHINE_TYPEt=${MACHINE_TYPE}"
```

`編集する時は` Cloud Shell Editor で編集してください(初回は編集しないで進めましょう）
```bash
edit ~/resonite-headless-infra/scripts/env-headless-server.bash
```

### **gcloud CLI の構成を管理する**

gcloud コマンドを使用してヘッドレスサーバのインフラを構築していきます。
事前に gcloud CLI の構成を設定します
```bash
PROJECT_NAME=$(gcloud config list --format="value(core.project)")
gcloud config set project ${PROJECT_NAME}
gcloud config set compute/zone ${ZONE}
gcloud config set compute/region ${REGION}
```

## **VPC ネットワークを作成する**

VPC を作成します
```bash
gcloud compute networks create ${VPC_NAME} --subnet-mode custom --mtu=1500
```

VPC が作成されたことを確認します
```bash
gcloud compute networks list --filter="name=${VPC_NAME}"
```

作成したVPCネットワークにリージョンとサブネットを割り当てます
```bash
gcloud compute networks subnets create ${SUBNET_NAME} \
    --network ${VPC_NAME} \
    --region ${REGION} \
    --range ${SUBNET_RANGE} \
    --enable-private-ip-google-access
```

サブネットが割り当てられたことを確認します
```bash
gcloud compute networks subnets list --filter="name=${SUBNET_NAME}"
```

## **ファイアウォールルールを作成する**

IAP から VPC ネットワークへのアクセスを許可します
```bash
gcloud compute firewall-rules create \
  allow-iap-forwarding-to-resonite-headless \
  --direction=INGRESS \
  --priority=1000 \
  --network=${VPC_NAME} \
  --allow=tcp:22,tcp:80,tcp:443,tcp:8080,icmp \
  --source-ranges=35.235.240.0/20
```

ヘッドレスサーバの forcePort へのアクセスを許可します
```bash
gcloud compute firewall-rules create allow-resonite-headless-forceport \
  --target-tags=${FIREWALL_TAG_NAME} \
  --direction=INGRESS \
  --priority=1000 \
  --network=${VPC_NAME} \
  --allow=udp:49151-49160 \
  --enable-logging \
  --source-ranges=0.0.0.0/0
```

ファイアウォールルールが作成されたことを確認します
```bash
gcloud compute firewall-rules list --filter="NOT(name:default)"
```

## **Config をシークレットに格納する**

ヘッドレスサーバの設定ファイル `Config.json` を `Secret Manager` に格納します。

カレントディレクトリをクローンしたリポジトリに変更します
```bash
REPOSITORY_DIR="${HOME}/resonite-headless-infra" && cd ${REPOSITORY_DIR}/config/
```

Config.json が存在することを確認する
```bash
HEADLESS_CONFIG_FILE=Config.json && ls -l ${HEADLESS_CONFIG_FILE}
```

`Config.json` を編集します ※Ctrl+s で上書き保存する
```bash
edit ${HEADLESS_CONFIG_FILE}
```

### **新しいシークレットをインスタンス名で作成する**
インスタンス名をシークレット名の変数に入れます（インスタンス名は resonite-headless-server）

```bash
HEADLESS_CONFIG_SECRET=${RESONITE_HEADLESS_SERVER_INSTANCE_NAME} && echo ${HEADLESS_CONFIG_SECRET}
```
ヘッドレスの config ファイルを Secret Manager に格納します
```bash
gcloud secrets create ${HEADLESS_CONFIG_SECRET} --data-file ${HEADLESS_CONFIG_FILE}
```

シークレットに格納されたことを確認します
```bash
gcloud secrets versions list ${HEADLESS_CONFIG_SECRET}
```

シークレットの内容を出力します
```bash
gcloud secrets versions access latest --secret ${HEADLESS_CONFIG_SECRET}
```

### **GCE インスタンス内部からシークレットへアクセスできるように設定する**

GCE インスタンスに紐づく Google Service Account を変数に入れます
```bash
GSA=$(gcloud projects describe $(gcloud config get-value project) --format="value(projectNumber)")-compute@developer.gserviceaccount.com && echo ${GSA}
```

作成したシークレットに対して IAM ポリシーバインディングを設定します
```bash
gcloud secrets add-iam-policy-binding ${HEADLESS_CONFIG_SECRET} --member serviceAccount:${GSA} --role roles/secretmanager.secretAccessor
```

シークレットへのアクセス権限を確認します
```bash
gcloud secrets get-iam-policy ${HEADLESS_CONFIG_SECRET}
```

## Resonite Headless Server 用インスタンスを作成する

カレントディレクトリをスクリプトが配置されたディレクトリに変更し OS セットアップファイルのテンプレートがあることを確認します
```bash
cd ${REPOSITORY_DIR}/scripts/ && ls -l setup-config.yaml.template
```

ヘッドレスサーバを作成する為に必要な情報を編集します
```bash
edit personal-information.json
```
```
# 編集内容
{
    "HEADLESS_PASSWORD": "フレンド欄の resonite に /headlessCode とメッセージを送って返ってくる文字列",
    "STEAM_USER": "ヘッドレスサーバ用に作成した Steam アカウント名",
    "STEAM_PASSWORD": "Steam アカウントのパスワード",
    "HEADLESS_USER": "ヘッドレスサーバ用に作成した Resonite ユーザ名"
}
```

GCE インスタンスを作成する為の設定ファイルを生成します
```bash
python gce_cloudinit_yaml_generator.py
```

`#cloud-config` で始まるファイルが生成された事を確認します
```bash
edit setup-config.yaml
```

GCE インスタンスを作成します
```bash
gcloud compute instances create ${RESONITE_HEADLESS_SERVER_INSTANCE_NAME} \
    --tags=${FIREWALL_TAG_NAME} \
    --image-project=${IMAGE_PROJECT} \
    --image-family=${IMAGE_FAMILY} \
    --image-family-scope=${IMAGE_FAMILY_SCOPE} \
    --machine-type=${MACHINE_TYPE} \
    --subnet=${SUBNET_NAME} \
    --metadata-from-file=user-data=${SETUP_RESONITE_HEADLESS_SERVER_SCRIPT} \
    --network-tier=STANDARD \
    --scopes cloud-platform
```
GCE インスタンスが作成され、ステータスが Running であることを確認します
```bash
gcloud compute instances describe ${RESONITE_HEADLESS_SERVER_INSTANCE_NAME} --format="value(status)"
```

5分程待てば、ヘッドレスサーバが起動しているはずです。クライアントから参加できるか確認してみてください

問題がなければインスタンスを停止しましょう
```bash
gcloud compute instances stop ${RESONITE_HEADLESS_SERVER_INSTANCE_NAME}
```

以上です。お疲れさまでした。

## **ヘッドレスサーバが起動しない場合の調査方法**

OS にログインして、GCE インスタンスの OS セットアップが完了しているかどうかを確認します

SSH で GCE インスタンスへログインします
```bash
gcloud compute ssh --tunnel-through-iap ${RESONITE_HEADLESS_SERVER_INSTANCE_NAME}
```

以下のようなメッセージが出ますが、全て Enter を押して問題ありません
```
WARNING: The private SSH key file for gcloud does not exist.
WARNING: The public SSH key file for gcloud does not exist.
WARNING: You do not have an SSH key for gcloud.
WARNING: SSH keygen will be executed to generate a key.
This tool needs to create the directory [/home/${HOME}/.ssh] before being able to generate SSH keys.

Do you want to continue (Y/n)?  ← Enter で良い

Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase): ※ ssh が使う秘密鍵のパスフレーズを要求されるが入力しなくても良い。鍵を削除し gcloud compute ssh 実行すればを再作成される
Enter same passphrase again: 
Your identification has been saved in /home/${HOME}/.ssh/google_compute_engine
～省略～
Waiting for SSH key to propagate.
～省略～
```

`/root/INITIALIZED` というファイルが存在していればセットアップが完了しています
```bash
sudo ls -l /root/INITIALIZED
```

`INITIALIZED` が存在していなかった場合、ログを確認し、エラーが出ていた場合は出力メッセージを元にして調査をします

エラーが出ていない場合は `command.log` を tail して `Succeeded.` と表示されるまで待ちます
```bash
sudo tail -f /root/command.log
```
成功した際のログ出力例
```
root@resonite-headless-server:~# tail -f command.log
2025-12-03 19:54:29 Start Scrpt
2025-12-03 19:54:30 Executed: sudo apt update
2025-12-03 19:54:41 Executed: sudo apt install -y software-properties-common
2025-12-03 19:54:47 Executed: sudo add-apt-repository -y multiverse
2025-12-03 19:54:47 Executed: sudo dpkg --add-architecture i386
2025-12-03 19:54:57 Executed: sudo add-apt-repository -y ppa:dotnet/backports
2025-12-03 19:54:59 Executed: sudo apt update
2025-12-03 19:54:59 Executed: echo steam steam/license note "" | sudo debconf-set-selections
2025-12-03 19:54:59 Executed: echo steam steam/question select "I AGREE" | sudo debconf-set-selections
2025-12-03 19:55:25 Executed: sudo apt install -y lib32gcc-s1 curl libopus-dev libopus0 opus-tools libc-dev tmux dstat powerline gnupg ca-certificates vim dotnet-runtime-9.0 steamcmd
2025-12-03 19:55:26 Executed: curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
2025-12-03 19:55:51 Executed: sudo bash add-google-cloud-ops-agent-repo.sh --also-install
2025-12-03 19:55:52 Executed: sudo apt autoremove -y
2025-12-03 19:55:52 Executed: echo steam steam/license note | sudo debconf-set-selections
2025-12-03 19:55:52 Executed: echo steam steam/question select "I AGREE" | sudo debconf-set-selections
2025-12-03 19:55:53 Executed: sudo apt install -y steamcmd
2025-12-03 19:57:07 Executed: sudo -u USER /usr/games/steamcmd +login STEAMUSER STEAMPASSWORD +app_license_request 2519830 +app_update 2519830 -beta headless -betapassword BETAPASSWORD validate +exit
2025-12-03 19:57:07 Executed: export RESONITE_HEADLESS_DIR="/home/go_yamada4649/.local/share/Steam/steamapps/common/Resonite/Headless"
2025-12-03 19:57:07 Executed: systemctl daemon-reload
2025-12-03 19:57:13 Executed: systemctl --now enable resonite-headless.service
2025-12-03 19:57:13 Executed: sudo touch ~/INITIALIZED
2025-12-03 19:57:13 Succeeded.
```

ヘッドレスサーバの Unit の状態を確認をします。ログの一部を確認できます
```bash
systemctl status resonite-headless.service
```
ヘッドレスサーバの Config.json を確認し、問題があれば修正します
```bash
HEADLESS_CONFIG_FILE=${RESONITE_HEADLESS_DIR}/Config/Config.json
nano ${HEADLESS_CONFIG_FILE}
```
ヘッドレスサーバを再起動します
```bash
sudo systemctl restart resonite-headless.service
```

GCE インスタンスのシェルから抜ける
```bash
exit
```

以上

