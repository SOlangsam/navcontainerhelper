﻿<# 
 .Synopsis
  Import Objects to Nav Container
 .Description
  Copy the object file to the Nav container if necessary.
  Create a session to a Nav container and run Import-NavApplicationObject
 .Parameter containerName
  Name of the container for which you want to enter a session
 .Parameter objectsFile
  Path of the objects file you want to import
 .Parameter vmadminUsername
  Username of the administrator user in the container (defaults to sa)
 .Parameter adminPassword
  The admin password for the container (if using NavUserPassword authentication)
 .Example
  Import-ObjectsToNavContainer -containerName test2 -objectsFile c:\temp\objects.txt -adminPassword <adminpassword>
#>
function Import-ObjectsToNavContainer {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$containerName, 
        [Parameter(Mandatory=$true)]
        [string]$objectsFile,
        [string]$vmadminUsername = 'sa',
        [SecureString]$adminPassword = $null
    )

    $containerAuth = Get-NavContainerAuth -containerName $containerName
    if ($containerAuth -eq "NavUserPassword" -and !($adminPassword)) {
        $adminPassword = Get-DefaultAdminPassword
    }

    $containerObjectsFile = Get-NavContainerPath -containerName $containerName -path $objectsFile
    $copied = $false
    if ("$containerObjectsFile" -eq "") {
        $containerObjectsFile = Join-Path "c:\run" ([System.IO.Path]::GetFileName($objectsFile))
        Copy-FileToNavContainer -containerName $containerName -localPath $objectsFile -containerPath $containerObjectsFile
        $copied = $true
    }

    $session = Get-NavContainerSession -containerName $containerName
    Invoke-Command -Session $session -ScriptBlock { Param($objectsFile, $vmadminUsername, $adminPassword, $copied)
    
        $customConfigFile = Join-Path (Get-Item "C:\Program Files\Microsoft Dynamics NAV\*\Service").FullName "CustomSettings.config"
        [xml]$customConfig = [System.IO.File]::ReadAllText($customConfigFile)
        $databaseServer = $customConfig.SelectSingleNode("//appSettings/add[@key='DatabaseServer']").Value
        $databaseInstance = $customConfig.SelectSingleNode("//appSettings/add[@key='DatabaseInstance']").Value
        $databaseName = $customConfig.SelectSingleNode("//appSettings/add[@key='DatabaseName']").Value
        if ($databaseInstance) { $databaseServer += "\$databaseInstance" }
    
        $params = @{}
        if ($adminPassword) {
            $params = @{ 'Username' = $vmadminUsername; 'Password' = ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword))) }
        }
        Write-Host "Importing Objects from $objectsFile"
        Import-NAVApplicationObject @params -Path $objectsFile `
                                    -DatabaseName $databaseName `
                                    -DatabaseServer $databaseServer `
                                    -ImportAction Overwrite `
                                    -SynchronizeSchemaChanges Force `
                                    -NavServerName localhost `
                                    -NavServerInstance NAV `
                                    -NavServerManagementPort 7045 `
                                    -Confirm:$false

        if ($copied) {
            Remove-Item -Path $objectsFile -Force
        }
    
    } -ArgumentList $containerObjectsFile, $vmadminUsername, $adminPassword, $copied
    Write-Host -ForegroundColor Green "Objects successfully imported"
}
Export-ModuleMember -Function Import-ObjectsToNavContainer
