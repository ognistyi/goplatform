$ErrorActionPreference = "Stop"

$repo    = "ognistyi/goplatform"
$binary  = "goplatform"
$installDir = "$env:LOCALAPPDATA\Programs\goplatform"

function Get-LatestVersion {
    $release = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest"
    return $release.tag_name
}

function Install-Binary($version) {
    $versionNum = $version.TrimStart("v")
    $filename   = "${binary}_${versionNum}_windows_amd64.exe"
    $url        = "https://github.com/$repo/releases/download/$version/$filename"

    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    $dest = "$installDir\$binary.exe"

    Write-Host "Downloading $filename..."
    Invoke-WebRequest -Uri $url -OutFile $dest

    # add to user PATH if missing
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*$installDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$userPath;$installDir", "User")
        $env:PATH += ";$installDir"
    }

    return $dest
}

$version = Get-LatestVersion
$dest    = Install-Binary $version

Write-Host "Installed $binary $version to $dest"
& $dest
