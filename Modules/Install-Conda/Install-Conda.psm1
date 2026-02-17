Function Install-Conda {
  winget install anaconda.miniconda3
  
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path /t REG_EXPAND_SZ /d "%PATH%;C:\programdata\miniconda3\scripts\" /f
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
  
  conda install -c conda-forge glances
}

