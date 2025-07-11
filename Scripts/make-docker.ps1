# make-docker.ps1
$ErrorActionPreference = "Stop"

$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host "Script directory: $SCRIPTDIR"

$TAG = $env:BUILD_NUMBER
$AWS_DEFAULT_REGION = $env:AWS_DEFAULT_REGION
$REPO_PREFIX = $env:REPO_PREFIX

Write-Host "Tag: $TAG"
Write-Host "Repo Prefix: $REPO_PREFIX"

$srcPath = Join-Path $SCRIPTDIR "..\src"
$directories = Get-ChildItem -Path $srcPath -Directory

foreach ($dir in $directories) {
    $svcname = $dir.Name

    if ($svcname.StartsWith(".")) {
        Write-Host "Skipping hidden directory: $svcname"
        continue
    }

    $builddir = $dir.FullName
    if ($svcname -eq "cartservice") {
        $builddir = Join-Path $builddir "src"
    }

    Set-Location $builddir

    docker system prune -f
    docker container prune -f

    $image = "${REPO_PREFIX}/${svcname}:${TAG}"
    Write-Host "Building and pushing: $image"

    aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $REPO_PREFIX

    docker build -t "$svcname" .
    docker tag "$svcname" "$image"
    docker push "$image"
}

Write-Host "Successfully built and pushed all the images."
