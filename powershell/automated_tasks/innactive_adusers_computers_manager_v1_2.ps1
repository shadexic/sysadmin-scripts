<# Created By ::          shadexic
   Created On ::          2021-07-13
   Modified On ::         2021-07-14 , 2021-07-16
   Modification Note ::   Added Disable Feature, Computer functionality, and preped script for review and deployment. see changes comment below for more details. version 1.2 is ready for deployment
   Version ::             1.2
   Github ::              github.com/shadexic
   Notes ::               Remove the -Whatif Flag once you have tested this script
                          (by checking the $report array after its run) | or by checking the logfile (note: the -whatif flag will cause users to be displayed as enabled in both log and $report until removed)
                          -whatif is located on the following lines;
                          75 76 108 109

                          Change DC parameters on the following lines to match your env; 53, 76, 84, 109, and 117 *halo theme starts* )

   Description ::         Will search the entire AD for users and computers that have a lastlogondate
                          more than 180 days and 30 days respectively (you cna configure different options)
                          and will disable those accounts before moving them over to the respective OU
                          for disabled users or computers.

                          filters located on lines 61 and 100 should be modified to suit your needs if desired
                          (although trying to touch the accound with the SamAccountName "Administrator" 
                          is highly discouraged)
   
   Changes 1.1 - 1.2      Updated Line 110 Col 198 | DistinguishedName Variable; was set to $user instead of $machine (machine segment was copied from user segment
                          User was not changed to machine for that segment. Issue was identified during -WhatIf testing)     

                          Added content to line 41; switch commenting with line 40 to switch logofile from .LOG or .csv file (identified as usefull for reviewing during tests)

Resources used (to assist with changes later on)

https://lazywinadmin.com/2014/04/powershell-get-list-of-my-domain.html
https://www.manageengine.com/products/ad-manager/powershell/script-disable-ad-computer.html
https://docs.microsoft.com/en-us/powershell/module/activedirectory/move-adobject?view=windowsserver2019-ps
https://stackoverflow.com/questions/50048581/moving-users-to-a-disabled-ou-in-powershell
#>

#get a timestamp for use in the logfile and the logfilename
$datetime = Get-Date -f yyyy-MM-dd_HH-mm-ss

#absolute path to the logfile (switch between the two if you'd prefer the default logfile with a csv or .LOG (typically opens with notepad) file extension
$logfile = "C:\temp\logfile-innactive-users-$($datetime).LOG"
#logfile = "C:\temp\logfile-innactive-users-$($datetime).csv" 
#generates a string of 180 days (or your choice) ago to use for checking if the last logon date is more than 180 days ago (the lastlogondate will be less than the $userdays)
$userdays = (get-date).AddDays(-180).ToString()

#same as $userdays, just for computers instead
$computerdays = (get-date).AddDays(-30).ToString()

#retreive all aduser objects that have a lastlogondate less than $userdays
$innactiveusers = get-aduser -Filter * -Properties LastLogonDate, SamAccountName | Where-Object -Property "LastLogonDate" -LT $userdays


#select only "real people" user accounts (by using the string like this we can avoid things like exchaange server objects)
$innactiveusers = $innactiveusers | Where-Object -Property DistinguishedName -Like "*OU=Corporate Users,DC=contoso,DC=com"


#select only user accounts that are enabled (not disabled)
$innactiveusers = $innactiveusers | Where-Object -Property Enabled -EQ True

#Don't take this out unless you want to have a fun time
#Seriously though, this removes the Administrator Account from the list, take care when changing this 
$innactiveusers = $innactiveusers | Where-Object -Property SamAccountName -NotLike "Administrator"
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#prepare an array to store users and computer objects for the
$report =@()

#get timestamp formated the same way that the LastLogonDate is stored as
$reporttimestamp = (get-date).ToString()


#counts to see if there actually are any users, if not it skips moving users
if ( $innactiveusers.Count -gt 0) {

    foreach ($user in $innactiveusers) {
    Disable-ADAccount -Identity $user.SamAccountName -WhatIf
    Move-ADObject -Identity $user.DistinguishedName -TargetPath "OU=InactiveUsers,DC=contoso,DC=com" -WhatIf
    $report += [pscustomobject]@{ObjectType="User";LastLogonDate=$user.LastLogonDate;Date=$reporttimestamp;Identifier=$user.SamAccountName;EnabledStatus=$user.Enabled;DistinguishedName=$user.DistinguishedName}
    }
}
#generate a "blank" entry in the logfile for visual aid in parsing the log
$report += [pscustomobject]@{ObjectType="User";LastLogonDate="";Date="";Identifier="";EnabledStatus="";DistinguishedName=""}

#after moving the user check the status of that account again (the previous array is not "updated")
$checkusers = Get-ADUser -Filter * -SearchBase "DC=contoso,DC=com" | Where-Object -Property SamAccountName -In $innactiveusers.SamAccountName

#checks to see if there are any users once more and skips if there are none.
if ($checkusers.Count -gt 0) {

    foreach ($user in $checkusers) {
    $report += [pscustomobject]@{ObjectType="User";LastLogonDate=$user.LastLogonDate;Date=$reporttimestamp;Identifier=$user.SamAccountName;EnabledStatus=$user.Enabled;DistinguishedName=$user.DistinguishedName}
    }
}
#############################################################################################################################################################################################################

#this segment is largely the same however it simply deals with inactive Computers


$inactivecomputers = Get-ADComputer -Filter * -Properties LastLogonDate | Where-Object -Property LastLogonDate -LT $computerdays

$inactivecomputers = $inactivecomputers | Where-Object -Property DistinguishedName -NotLike "*exch*" # excludes Exchange Servers, just for percaution

$inactivecomputers = $inactivecomputers | Where-Object -Property Enabled -EQ True

#counts to see if there actually are any computers, if not it skips moving users
if ( $inactivecomputers.Count -gt 0) {
    
    foreach ($machine in $inactivecomputers) {
    Set-ADComputer -Identity $machine.SamAccountName -Enabled $false -WhatIf
    Move-ADObject -Identity $machine.DistinguishedName -TargetPath "OU=InactiveComputers,DC=contoso,DC=com" -WhatIf
    $report += [pscustomobject]@{ObjectType="Machine";LastLogonDate=$machine.LastLogonDate;Date=$reporttimestamp;Identifier=$machine.SamAccountName;EnabledStatus=$machine.Enabled;DistinguishedName=$machine.DistinguishedName}
    }
}
#generate a "blank" entry in the logfile for visual aid in parsing the log
$report += [pscustomobject]@{ObjectType="machine";LastLogonDate="";Date="";Identifier="";EnabledStatus="";DistinguishedName=""}

#after moving the machine check the status of that account again (the previous array is not "updated")
$checkmachines = Get-ADComputer -Filter * -SearchBase "DC=contoso,DC=com" | Where-Object -Property SamAccountName -In $inactivecomputers.SamAccountName


#checks to see if there are any users once more and skips if there are none.
if ($checkmachines.Count -gt 0) {

    foreach ($machine in $checkmachines) {
    $report += [pscustomobject]@{ObjectType="machine";LastLogonDate=$machine.LastLogonDate;Date=$reporttimestamp;Identifier=$machine.SamAccountName;EnabledStatus=$machine.Enabled;DistinguishedName=$machine.DistinguishedName}
    }
}

#comment out this line if you don't want a log file
$report | export-csv $logfile
