import json
import os
from string import Template

class CustomTemplate(Template):
    delimiter = '%%'  # '$' から '%%' に変更

def generate_config():
    # 個人情報の読み込み
    with open('personal-information.json', 'r', encoding='utf-8') as f:
        personal_info = json.load(f)

    # 環境変数からUSERを取得し、辞書に追加
    user = os.environ.get('USER')
    if user:
        personal_info['USER'] = user
    else:
        raise EnvironmentError('Neither USER environment variable is set')

    # テンプレートファイルの読み込み
    with open('setup-config.yaml.template', 'r', encoding='utf-8') as f:
        template_content = f.read()

    # カスタムテンプレートを使用して置換を実行
    template = CustomTemplate(template_content)
    try:
        config_content = template.substitute(personal_info)
    except KeyError as e:
        raise KeyError(f'Template variable {e} not found in personal information or environment variables')

    # 設定ファイルの生成
    try:
        with open('setup-config.yaml', 'w', encoding='utf-8') as f:
            f.write(config_content)
        print(f"setup-config.yaml を生成しました")
    except Exception as e:
        print(f"エラーになりました: {e}")


if __name__ == '__main__':
    generate_config()
