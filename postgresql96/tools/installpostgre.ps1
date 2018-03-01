
# 9.1.1-1
# $postgresql_exe_url64 = 'http://get.enterprisedb.com/postgresql/postgresql-9.1.1-1-windows-x64.exe'
# $postgresql_exe_url32 = 'http://get.enterprisedb.com/postgresql/postgresql-9.1.1-1-windows.exe'

# 9.2.1-1
# $postgresql_exe_url64 = 'http://get.enterprisedb.com/postgresql/postgresql-9.2.1-1-windows-x64.exe'
# $postgresql_exe_url32 = 'http://get.enterprisedb.com/postgresql/postgresql-9.2.1-1-windows.exe'

# 9.3.5-1
# $postgresql_exe_url64 = 'http://get.enterprisedb.com/postgresql/postgresql-9.3.5-1-windows-x64.exe'
# $postgresql_exe_url32 = 'http://get.enterprisedb.com/postgresql/postgresql-9.3.5-1-windows.exe'

# 9.4.0-1
# $postgresql_exe_url64 = 'http://get.enterprisedb.com/postgresql/postgresql-9.4.0-1-windows-x64.exe'
# $postgresql_exe_url32 = 'http://get.enterprisedb.com/postgresql/postgresql-9.4.0-1-windows.exe'

# 9.6.8-1
$postgresql_exe_url64 = 'http://get.enterprisedb.com/postgresql/postgresql-9.6.8-1-windows-x64.exe'
$postgresql_exe_url32 = 'https://get.enterprisedb.com/postgresql/postgresql-9.6.8-1-windows.exe'

$postgrePath        = "$(Get-BinRoot)\postgresql96"
$postgreAccount     = 'postgresql'
$postgrePassword    = 'Postgres-1234'
$postgreServiceName = 'postgresql96'

Write-Host "PostgreSQL Install Path:....... $postgrePath"
Write-Host "PostgreSQL Install Account....: $postgreAccount"
Write-Host "PostgreSQL Install Password...: $postgrePassword"
Write-Host "PostgreSQL Install ServiceName: $postgreServiceName"

try {

  Write-Host "Deleting and recreating $postgreAccount windows account..."
  try {
    net user $postgreAccount /delete
  } catch {
    Write-Host "Cannot delete user. User $postgreAccount doesn`'t exist. Which is perfectly fine, it will be created in the next step."
  }

  $localUser = ([ADSI]"WinNT://$env:computername").Create("User", $postgreAccount)
  $localUser.SetPassword($postgrePassword)
  $localUser.SetInfo()

  try {
    $localUserPath = "WinNT://$env:computername/$postgreAccount"
    $computer      = [ADSI]("WinNT://$env:computername,computer")
    $localGroup    = $computer.PSBase.Children.Find("Users")
    $sysInfo       = Get-WmiObject -Class Win32_ComputerSystem 
    $workGroup     = $sysInfo.Workgroup
    if ($localGroup.PSBase.Path -like 'WinNT://' + $workGroup + '*') {
      $localUserPath = "WinNT://$workGroup/$env:computername/$postgreAccount"
    }
    if ($localGroup.PSBase.Invoke("IsMember",$localUserPath)) {
      $localGroup.PSBase.Invoke("Remove",$localUserPath)
    }
  } catch {
    write-host "Removing $postgreAccount from Users failed. Please do that manually"
    start-sleep 5
  }
  
  Write-Host "The account $postgreAccount has been created with the password set to $postgrePassword. Please change the password for the $postgreAccount account and update the services to that password"
  Start-Sleep 4
  

  Write-Host "Creating $postgrePath folder for installation if it doesn`'t exist"
  if (![System.IO.Directory]::Exists($postgrePath)) {[System.IO.Directory]::CreateDirectory($postgrePath)}

  Write-Host "Setting folder permissions on $postgrePath to full control for user postgres"
  $acl = Get-Acl $postgrePath
  $acl.SetAccessRuleProtection($True, $True)
  $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("$postgreAccount","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow");
  $acl.AddAccessRule($rule);
  Set-Acl $postgrePath $acl
  
  $installArgs = "--mode unattended --prefix $postgrePath --datadir $($postgrePath)\data --servicename $postgreServiceName --superaccount $postgreAccount --superpassword $postgrePassword --serviceaccount $postgreAccount"

  Install-ChocolateyPackage 'postgresql' 'exe' "$installArgs" "$postgresql_exe_url" "$postgresql_exe_url64"

  Install-ChocolateyPath "$($postgrePath)\bin"
  
  Write-ChocolateySuccess 'postgresql'
} catch {
  Write-ChocolateyFailure 'postgresql' "$($_.Exception.Message)"
  throw 
}



