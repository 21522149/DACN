$ErrorActionPreference = "Stop"

$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host "Script Directory: $SCRIPTDIR"

$TAG = $env:BUILD_NUMBER
$AWS_DEFAULT_REGION = $env:AWS_DEFAULT_REGION
$REPO_PREFIX = $env:REPO_PREFIX

Write-Host "Build Tag: $TAG"
Write-Host "Repo Prefix: $REPO_PREFIX"

$dirs = Get-ChildItem -Path "$SCRIPTDIR\..\src" -Directory

foreach ($dir in $dirs) {
    $svcname = $dir.Name
    if ($svcname.StartsWith(".")) {
        Write-Host "Skipping hidden directory: $svcname"
        continue
    }

    $builddir = $dir.FullName
    if ($svcname -eq "cartservice") {
        $builddir = Join-Path $dir.FullName "src"
    }

    Set-Location $builddir

    docker system prune -f
    docker container prune -f

    $image = "$REPO_PREFIX$svcname:$TAG"
    Write-Host "Building and pushing: $image"

    aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $REPO_PREFIX
    docker build -t $svcname .
    docker tag $svcname $image
    docker push $image
}

Write-Host "✅ Successfully built and pushed all the images"
