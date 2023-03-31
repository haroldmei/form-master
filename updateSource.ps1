#This script installs Python with common libraries. It must be executed in PowerShell ISE
$form_master = 'https://github.com/haroldmei/form-master/archive/refs/heads/main.zip'
$downloadFolder = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path

$fmFileName = Split-Path -Path $form_master -Leaf
$fmFilePath = Join-Path -Path $downloadFolder -ChildPath $fmFileName
Invoke-WebRequest -Uri $form_master -OutFile $fmFilePath
Expand-Archive $fmFilePath -DestinationPath C:\ -Force
