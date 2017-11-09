﻿<# 
 .Synopsis
  Get the country version of Nav for a Nav container or a Nav container image
 .Description
  Returns the country version (localization) for the version of Nav in the Nav container or Nav containerImage
  Financials versions of Nav will be preceeded by 'fin', like finus, finca, fingb.
 .Parameter containerOrImageName
  Name of the container or container image for which you want to get the country version
 .Example
  Get-NavContainerCountry -containerOrImageName navserver
 .Example
  Get-NavContainerCountry -containerOrImageName navdocker.azurecr.io/dynamics-nav:2017
#>
function Get-NavContainerCountry {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$containerOrImageName
    )

    Process {
        $inspect = docker inspect $containerOrImageName | ConvertFrom-Json
        return "$($inspect.Config.Labels.country)"
    }
}
Export-ModuleMember -function Get-NavContainerCountry
