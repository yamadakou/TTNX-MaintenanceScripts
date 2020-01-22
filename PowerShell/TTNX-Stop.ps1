# TTNXをメンテナンスモードに移行するPowerShellスクリプト
# * TTNX4.2以降の非公開APIを利用
# * Windows Server 2012 R2（PowerShell 4.0） + TTNX4.3 の環境で動作確認済み


# TTNXのルートURL（末尾は"/"とすること）
# * 以下はデフォルトのままインストールした際の値を記載
$TTNX_ROOT_URL = "http://localhost/TimeTrackerNX/"

# TTNXのWebAPI呼び出し時のユーザー情報（システム管理権限のあるユーザーを指定）
$USER = "{'LoginName' of the user who can log in to TTNX}"
$PASS = "{Login user password}"


## WebAPIを呼び出す際の認証用トークンを取得

$BODY = @{loginName=$USER; password=$PASS}
$REST_API = $TTNX_ROOT_URL + "api/auth/token"

# [DEBUG用]WebAPI呼び出しに使用するBodyの内容を確認
Write-Output $BODY

try {
  $responseToken = Invoke-RestMethod -Uri $REST_API -Method POST -Body $BODY
} catch {
  # HTTPステータスコードと詳細を出力し、終了する。
  Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
  Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
  return "Error getting token"
}

# [DEBUG用]取得した認証用トークンの内容を確認
Write-Output $responseToken


## TTNXのメンテナンスモード移行を要求

# 認証用トークンの内容をHeaderに指定

$HEAD = @{Authorization="Bearer " + $responseToken.token}

# [DEBUG用]WebAPI呼び出しに使用するHeaderの内容を確認
Write-Output $HEAD

$REST_API = $TTNX_ROOT_URL + "api/sysadmin/application"
try {
  $response = Invoke-RestMethod -Uri $REST_API -Method PUT -Body @{maintenance="true"} -Headers $HEAD -ContentType "application/json"
} catch {
  # HTTPステータスコードと詳細を出力し、終了する。
  Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
  Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
  return "Error in maintenance mode transition request"
}

# [DEBUG用]取得したレスポンスの内容を確認
Write-Output $response


# TTNXがメンテナンスモードになるまでチェック（1秒ごとで最大60回）
$result = 0
for ($i = 0; $i -lt 60; $i++) {
  try {
    $response = Invoke-RestMethod -Uri $REST_API -Method GET -Headers $HEAD -ContentType "application/json"
  } catch {
    # HTTPステータスコードと詳細を出力し、終了する。
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
    return "Error getting  maintenance mode status"
  }

  # [DEBUG用]取得したレスポンスの内容を確認
  Write-Output $response

  # メンテナンスモードに移行したらでチェック終了
  if($response.status -eq "Suspend") {
    $result = 1
    break
  }

  # 1秒待機
  Start-Sleep -s 1
}

if($result -eq 1) {
  # 正常終了
  return "Success"
} else {
  # 1分以内にメンテナンスモードに移行できなかった
  return "Failed to enter maintenance mode within 1 minute"
}
