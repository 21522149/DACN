$ErrorActionPreference = "Stop"

$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host "Script directory: $SCRIPTDIR"

$TAG = $env:BUILD_NUMBER
$AWS_DEFAULT_REGION = $env:AWS_DEFAULT_REGION
$REPO_PREFIX = $env:REPO_PREFIX.TrimEnd("/")  # Trim dấu '/' nếu có

Write-Host "Tag: $TAG"
Write-Host "Repo Prefix: $REPO_PREFIX"

$REGISTRY_URI = $REPO_PREFIX  # alias cho dễ nhìn

# Login một lần duy nhất (quan trọng!)
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $REGISTRY_URI

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

    #Đường image đầy đủ: <registry>/<servicename>:<tag>
    $image = "$REGISTRY_URI/$svcname:$TAG"
    Write-Host "Building and pushing: $image"

    docker build -t "$svcname" .
    docker tag "$svcname" "$image"
    docker push "$image"
}

Write-Host "Successfully built and pushed all the images."
