#
# ps1 wrapper for psm1
#
#
Param(
    [Parameter(Mandatory=$true)][string]$url,
    [Parameter(Mandatory=$true)][string]$file
)

# Gets the project directory
$ProjDir = $(git rev-parse --show-toplevel).Replace("/", "\")

Import-Module "$ProjDir\scripts\Modules\download-module.psm1"

DownloadFileWithProgress $url $file

