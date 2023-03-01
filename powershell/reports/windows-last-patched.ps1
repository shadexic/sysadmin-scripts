  
<# Created by   ::  mfreymond 
   Created on   ::  2020-06-29
   Modified by  ::  shadexic
   Modified on  ::  2020-07-28
   Version      ::  2.0
   Description  ::  Retreives a list of servers from AD and determines the last security patch, security patch ID, who installed the patch (account)
                    and when the patch was applied.

   Modification ::  added ability to add operating system version through the use of the win32_operatingsystem option, removed unecessary and duplicated columns within the generated report
                    changed method of storing all collection data, instead of writing and appending to the file all information is stored within a ps.customobject and written to disk at
                    the end of the script.
#>

## lines to change: line 19 (file path) | line 22 (where-distinguished name your_string)
# $ErrorActionPreference= 'silentlycontinue'

$xxx=(Get-Date).ToString("yyyy_MM_dd")
$fileName='\\network\path\to\report\file (you could also use a local store if you wish)' + $xxx + '_Windows_Updates_Last_Install.csv'


$ADComputerList = Get-ADComputer -Properties distinguishedName,OperatingSystem, Name -Filter * -ResultSetSize $null | where {$($PSItem.distinguishedName) -like '*your_string*' -or $($PSItem.OperatingSystem -like "*Server*") } | Select-Object Name


$HotFixList = ''
$logdata =@()
ForEach ($Name in $ADComputerList) {

	Write-host "Attempting to connect to "$Name.Name "." 
	
	If (Test-Connection $Name.Name -Count 1){
		$hottemp = Get-HotFix -ComputerName $Name.Name | Sort-Object InstalledOn -Descending | Select-Object -First 1 #| Export-csv -Append $fileName -NoTypeInformation
        $osname = (Get-WmiObject -ComputerName $Name.Name -Class Win32_OperatingSystem).name
        $osclean = $osname.Substring(0, $osname.IndexOf('|'))
        $osname = $osclean
        $logdata += [pscustomobject]@{servername=$Name.Name;os=$osname;hotfixid=$hottemp.HotFixID;installdate=$hottemp.InstalledOn;installedby=$hottemp.InstalledBy}

	}
	else {
		Write-host $Name.Name " Connection Error"
	}
} 
$logdata | Export-Csv $fileName -NoTypeInformation # | Sort-Object InstalledOn | export-csv $fileName
