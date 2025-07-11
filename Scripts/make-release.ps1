$ErrorActionPreference = "Stop"

# Lấy thư mục hiện tại của script
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host "Script directory: $ScriptDir"

# Biến môi trường
$REPO_PREFIX = $env:REPO_PREFIX
$GITHUB_TOKEN = $env:GITHUB_TOKEN
$GIT_USER_NAME = $env:GIT_USER_NAME
$GIT_REPO_NAME = $env:GIT_REPO
$TAG = $env:BUILD_NUMBER

# Hàm chỉnh sửa file YAML Kubernetes
function Edit-K8s {
    $srcPath = Join-Path $ScriptDir "..\src"
    $manifestPath = Join-Path $ScriptDir "..\kubernetes-manifests"

    Get-ChildItem -Path $srcPath -Directory | ForEach-Object {
        $svcname = $_.Name

        if ($svcname.StartsWith(".")) {
            Write-Host "Skipping hidden directory: $svcname"
            return
        }

        $image = "$REPO_PREFIX$svcname:$TAG"
        Write-Host "Updating image: $image"

        $yamlFile = Join-Path $manifestPath "$svcname.yaml"

        if (Test-Path $yamlFile) {
            (Get-Content $yamlFile) | ForEach-Object {
                if ($_ -match "image:.*$svcname.*") {
                    "image: $image"
                } else {
                    $_
                }
            } | Set-Content $yamlFile
        } else {
            Write-Warning "File not found: $yamlFile"
        }
    }

    # Commit và push
    Set-Location (Join-Path $ScriptDir "..")

    git add kubernetes-manifests/
    git commit -m "updates manifest files to $TAG version"
    git push "https://$GITHUB_TOKEN@github.com/$GIT_USER_NAME/$GIT_REPO_NAME" HEAD:master
}

# Gọi hàm
Edit-K8s
