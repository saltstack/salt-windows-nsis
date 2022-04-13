#
# ps1 wrapper for psm1
#
#
Param(
    [Parameter(Mandatory=$true)][string]$url,
    [Parameter(Mandatory=$true)][string]$file
)

# Gets the project directory
$script_dir = dir "$($myInvocation.MyCommand.Definition)"
$script_dir = $script_dir.DirectoryName

Import-Module "$script_dir\Modules\download-module.psm1"

DownloadFileWithProgress $url $file

