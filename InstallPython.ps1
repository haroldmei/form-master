#This script installs Python with common libraries. It must be executed in PowerShell ISE
$behindFirewall = $true #Set to $true if you are at the office, and $false otherwise
$python_url = 'https://www.python.org/ftp/python/3.11.1/python-3.11.1-amd64.exe' #Change URL if you need a different version
$installPython = $true #Set to false if Python is installed, and you only want to install/update libraries
#$proxy = 'http://0.0.0.0:8080' #proxy (not needed any more)
$list_libraries = "pandas pynput selenium python-docx fire" #list of libraries to install or update
$form_master = 'https://github.com/haroldmei/form-master/archive/refs/heads/main.zip'
$targetDir = "C:\Python"

$downloadFolder = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
if ($installPython) {
	#Specify the target location in the user's Downloads folder
	$downloadFileName = Split-Path -Path $python_url -Leaf
    $downloadFilePath = Join-Path -Path $downloadFolder -ChildPath $downloadFileName
	#launch download of the desired version
	Invoke-WebRequest -Uri $python_url -OutFile $downloadFilePath

	#Command to execute an install for the current user (no admin rights required)
    Start-Process -FilePath "$downloadFilePath" -ArgumentList "InstallAllUsers=0", "InstallLauncherAllUsers=0", "PrependPath=1", "TargetDir=$targetDir", "DefaultAllUsersTargetDir=$targetDir" -wait
    #Wait the end of installation process to continue
}
#Refresh environment variable Path:
$Env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
C:\Python\python.exe --version #Check installed version

#Install or upgrade all dependancies (pip,...)
$proxy_chain = if($behindFirewall) {' --trusted-host pypi.org --trusted-host files.pythonhosted.org'} else {''}
#$proxy_chain = if($behindFirewall) {' --trusted-host pypi.org --trusted-host files.pythonhosted.org --proxy=' + $proxy} else {''}

Start-Process -FilePath "C:\Python\python.exe" -ArgumentList "-m", "pip", "install", "--upgrade", "pip", $proxy_chain -wait #First upgrade pip

$fmFileName = Split-Path -Path $form_master -Leaf
$fmFilePath = Join-Path -Path $downloadFolder -ChildPath $fmFileName
Invoke-WebRequest -Uri $form_master -OutFile $fmFilePath
Expand-Archive $fmFilePath -DestinationPath C:\ -Force

$command = 'C:\Python\python.exe -m pip install --upgrade ' + $list_libraries + $proxy_chain	#install/upgrade libraries
Invoke-Expression $command

# Install form-master package itself (if already published to PyPI)
Write-Host "Installing form-master package..."
try {
    Invoke-Expression "C:\Python\python.exe -m pip install form-master$proxy_chain"
    Write-Host "form-master package installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Could not install form-master package from PyPI. Installing from local source..." -ForegroundColor Yellow
    Invoke-Expression "C:\Python\python.exe -m pip install -e .$proxy_chain"
}

Invoke-Expression '.\context.reg'