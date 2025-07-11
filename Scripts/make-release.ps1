# Stop script on error
$ErrorActionPreference = "Stop"

# Get script directory
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host "Script directory: $SCRIPTDIR"

# Load environment variables from Jenkins
$TAG = $env:BUILD_NUMBER
$AWS_DEFAULT_REGION = $env:AWS_DEFAULT_REGION
$REPO_PREFIX = $env:REPO_PREFIX
$GIT_USER_NAME = $env:GIT_USER_NAME
$GITHUB_TOKEN = $env:GITHUB_TOKEN
$GIT_REPO_NAME = $env:GIT_REPO_NAME

Write-Host "Using tag: $TAG"
Write-Host "Repo prefix: $REPO_PREFIX"

# Update manifest files
$srcPath = Join-Path $SCRIPTDIR "..\\src"
$manifestsPath = Join-Path $SCRIPTDIR "..\\kubernetes-manifests"

$directories = Get-ChildItem -Path $srcPath -Directory

foreach ($dir in $directories) {
    $svcname = $dir.Name

    if ($svcname.StartsWith(".")) {
        Write-Host "Skipping hidden directory: $svcname"
        continue
    }

    $image = "${REPO_PREFIX}${svcname}:${TAG}"
    Write-Host "Updating image for ${svcname}: ${image}"

    $manifestFile = Join-Path $manifestsPath "${svcname}.yaml"

    if (Test-Path $manifestFile) {
        (Get-Content $manifestFile) -replace "image:.*$svcname.*", "image: $image" |
            Set-Content $manifestFile
    } else {
        Write-Host "Warning: Manifest file not found: $manifestFile"
    }
}

# Git commit & push
cd (Join-Path $SCRIPTDIR "..")

# Configure Git identity
git config user.email "thanhhuy2017tv@gmail.com"
git config user.name "21522149"

git add kubernetes-manifests/
try {
    git commit -m "Update manifest files to version $TAG"
} catch {
    Write-Host "Nothing to commit."
}

# Pull to avoid conflict (if any), then push using token auth
$remoteUrl = "https://$GITHUB_TOKEN@github.com/$GIT_USER_NAME/$GIT_REPO_NAME.git"
git pull $remoteUrl main --rebase
git push $remoteUrl HEAD:main

Write-Host "Manifest files updated and pushed to GitHub"
