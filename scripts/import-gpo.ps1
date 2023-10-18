Write-Output "`n---Configuring Group Policy"
$gpresultOutput = (gpresult /r)
$gpresultOutput | Set-Content -Path "../logs/gpresult.txt"
# ^somehow parse this properly

Foreach ($gpoitem in Get-ChildItem ".\../GPOs") {
    Write-Output "Importing Group Policy $gpoitem"
    cmd /c LGPO.exe /g ../GPOs
}
gpupdate /force
