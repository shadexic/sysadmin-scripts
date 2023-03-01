<# Created By ::          Shadexic
   Created On ::          2021-07-13
   Version ::             1.0
   Description ::         Will retreive all users in the specified OU from Active Directory that are to be disabled but are still enabled
                          Will Generate a LogFile in the $logfile path variable with a timestamp and a status of the accounts both before
                          and after the script attempts to disable the accounts. if for some reason the accounts are unable to be disabled
                          the logfile will show "true" in the IsEnabledAfter column for that entry. the logfile seperates the two status 
                          listings of before and after with the "string" (values in the csv) of "checking that accounts disabled"
#>

#get a timestamp for use in the logfile and the logfilename
$datetime = Get-Date -f yyyy-MM-dd_HH-mm-ss

#retreive a list of all users in the desired OU NOTE: https://lazywinadmin.com/2014/04/powershell-get-list-of-my-domain.html 
#                                                     is a good resouce for determining your -searchbase Parameters
$disableaccounts = Get-ADUser -Filter * -SearchBase "OU=optional_sub_ou,OU=Corporate - Disabled Users,DC=contoso,DC=com" | Select-Object -Property SamAccountName, Name, ObjectClass, ObjectGUID, Enabled 

#select users that are still enabled in the previous OU
$stillenabled = $disableaccounts | Where-Object -Property Enabled -EQ true

#prepares the variable where the Logfile will be saved to
$logfile = "C:\temp\disable-ad-accounts-$($datetime).LOG"


#initialize the pscustomobject that will be used to hold the contents of the logfile
$report =@()

#loop through each account that is to be dissabled, but before disabling it store the pre-disable status in the logfile object
foreach ($account in $stillenabled) {
$report += [pscustomobject]@{SamAccountName=$account.SamAccountName;IsEnabledBefore=$account.Enabled;IsEnabledAfter="n/a";Date=$datetime}
Disable-ADAccount -Identity $account.SamAccountName -WhatIf

}

#add string values to the logfile to assist with identifying where the script switches from attempting to disable the accounts
#to checking the accounts for their status
$report += [pscustomobject]@{SamAccountName="checking";IsEnabledBefore="that";IsEnabledAfter="accounts";Date="disabled"}


# retreives users and status again from the AD and uses the report (which only lists each account it attempted once) to select the names and status of the account now
$checkusers = Get-ADUser -Filter * -SearchBase "OU=optional_sub_ou,OU=Corporate - Disabled Users,DC=contoso,DC=com" | Select-Object -Property SamAccountName, Name, ObjectClass, ObjectGUID, Enabled | 
Where-Object -Property SamAccountName -In $report.SamAccountName

#writes each entry here to the logfile to allow for investigation if required
foreach ($account in $checkusers) {
$report += [pscustomobject]@{SamAccountName=$account.SamAccountName;IsEnabledBefore="n/a";IsEnabledAfter=$account.Enabled;Date=$datetime}
}

#write the logfile to the specified directory.
$report | Export-Csv $logfile
