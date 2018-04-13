# Update Hugo static site generator

# Get version of the local Hugo
$localHugoVersionOutput = hugo version

if ($localHugoVersionOutput -notmatch ".* v([0-9.]+) .*")
{
    Write-Output "Could not find Hugo version number in the following output:"
    Write-Output $localFossilVersionOutput
    exit 1
}

$localHugoVersion = $Matches[1]

Write-Output "Local Hugo version: $localHugoVersion"

# Get version and URI of the remote Hugo
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
$latestReleaseHtml = (Invoke-WebRequest -Uri https://github.com/gohugoio/hugo/releases/latest).ParsedHtml
$latestReleaseVersion = $latestReleaseHtml.querySelector("h1.release-title > a").innerHtml

if ($latestReleaseVersion -notmatch "v([0-9.]+)")
{
    Write-Output "Could not match version number in the following release string:"
    Write-Output $latestReleaseVersion
    exit 1
}

$remoteHugoVersion = $Matches[1]

Write-Output "Remote Hugo version: $remoteHugoVersion"

# Update Hugo, if needed
if ($remoteHugoVersion -ne $localHugoVersion)
{
    Write-Output "Updating..."
    # Get OS bit width
    $osBits = if ([environment]::Is64BitOperatingSystem) {"64bit"} else {"32bit"}
    # Download zip file
    $remoteZipFileUri = "https://github.com/gohugoio/hugo/releases/download/$latestReleaseVersion/hugo_$remoteHugoVersion" +
                        "_Windows-$osBits.zip"  # The splitting is intentional, as PowerShell glues the underscore to the previous varible
    $tmpZipFile = "$env:TEMP\hugo.zip"
    Invoke-WebRequest -Uri $remoteZipFileUri -OutFile $tmpZipFile
    # Expand zip file to a temporary directory
    $tmpDirectory = "$env:TEMP\update-hugo"
    New-Item -Type Directory -Path $tmpDirectory | Out-Null
    Expand-Archive -LiteralPath $tmpZipFile -DestinationPath $tmpDirectory
    # Replace Hugo binary
    $localHugoDirectory = (Get-Command hugo).Path | Split-Path -Parent
    Move-Item -Path "$tmpDirectory\hugo.exe" -Destination $localHugoDirectory -Force
    # Clean up
    Remove-Item $tmpDirectory -Recurse -Force
    Remove-Item $tmpZipFile -Force
    Write-Output "Done"
}
else
{
    Write-Output "No update needed"
}