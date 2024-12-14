# Google Cloud Shell をセットアップする

## 主な作業
本チュートリアルでは Resonite ヘッドレスサーバを構築する為の環境をセットアップします。

主に下記をインストール、設定します

- `mise`
- `fzf`
- `.bash_profile`

## mise と fzf をインストールする

右側の `Cloud Shell` へコピーするボタンをクリックし、ターミナルで Enter を押してください

```bash
curl https://mise.run | sh
```

mise をアクティベイトします
```bash
echo "eval \"\$(/home/go_yamada4649/.local/bin/mise activate bash)\"" >> ~/.bashrc
```

シェルを一度終了します
```bash
exit
```

ターミナルが閉じるので(ターミナルが閉じなかったら閉じるまで exit を打ってください)、ブラウザ右上の **ターミナルを開く** ボタンをクリックします  
ターミナル画面が表示されたら、 **▼** ボタンをクリックしプロジェクトをクリックするとシェルが起動します

mise のバージョンを確認しましょう
```bash
mise --version
```

fzf コマンドをグローバルにインストールしてみましょう
```bash
mise use --global fzf
```

fzf のバージョンを確認しましょう
```bash
fzf --version
```

mise 上で fzf の状態を確認しましょう
```bash
mise ls fzf
```

## シェルの設定をする
Google Compute Engine を便利に扱うコマンドを bash プロファイルに仕込みます

```bash
mv resonite-headless-infra/scripts/bash_profile.txt ~/.bash_profile
```

以上で準備は終了です。

## 続けて Resonite ヘッドレスサーバを構築する

Steamガードをオフにしてからヘッドレスサーバの構築手順を実施してください
```bash
teachme resonite-headless-infra/build-resonite-headless.md
```
