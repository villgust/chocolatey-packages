try { 
  $toolsDir ="$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
  Start-ChocolateyProcessAsAdmin "& $($toolsDir)\installpostgre.ps1"

  Write-ChocolateySuccess 'postgresql96'
} catch {
  Write-ChocolateyFailure 'postgresql96' "$($_.Exception.Message)"
  throw 
}