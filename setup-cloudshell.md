# Google Cloud Shell をセットアップする

## 主な作業
本チュートリアルでは Resonite ヘッドレスサーバを構築する為の環境をセットアップします。

主に下記をインストール、設定します

- `mise`
- `fzf`
- `.bashrc`

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

fzf のバージョンを確認しましょう ※ fzf コマンドが見つからない場合は exit として再度ターミナルを開きなおしてください
```bash
fzf --version
```

mise 上で fzf の状態を確認しましょう
```bash
mise ls fzf
```

## シェルの設定をする
Google Compute Engine を便利に扱うコマンドを bash 設定ファイルに仕込みます

```bash
cat resonite-headless-infra/scripts/bashrc.txt >> ~/.bashrc
```

コマンドを打ち終わったら、exit して再度ターミナルを開いてください

以上で準備は終了です。

## 続けて Resonite ヘッドレスサーバを構築する

Steamガードをオフにしてからヘッドレスサーバの構築手順を実施してください
```bash
teachme resonite-headless-infra/build-resonite-headless.md
```
