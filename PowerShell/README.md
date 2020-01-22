# TTNXをメンテナンスモードに移行するPowerShellスクリプト

## 使い方
1. `TTNX-Stop.ps1` に記載のTTNXのURLとユーザー情報を環境に合わせて更新します。
```powershell
・・・
# TTNXのルートURL（末尾は"/"とすること）
# * 以下はデフォルトのままインストールした際の値を記載
$TTNX_ROOT_URL = "http://localhost/TimeTrackerNX/" ←環境に合わせる

# TTNXのWebAPI呼び出し時のユーザー情報（システム管理権限のあるユーザーを指定）
$USER = "admin-user" ←システム管理権限のあるユーザーを記載
$PASS = "password" ←上記ユーザーのパスワードを記載
・・・
```

2. バッチファイルから呼び出す場合、 `powershell`コマンドを使用します。
```cmd
powershell -NoProfile -ExecutionPolicy Unrestricted {パスを記載}\TTNX-STOP.ps1
```

## 備考
* TTNX4.2以降の非公開APIを利用
* Windows Server 2012 R2（PowerShell 4.0） + TTNX4.3 の環境で動作確認済み
