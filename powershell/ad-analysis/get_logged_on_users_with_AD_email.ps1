<# Created by: Shadexic
   Created on: 12-07-2021
   Version   : 1.2
   Description: Import a list of Hostnames of machines on the domain, then attempt to resolve the current logged on user to those machines.
   will then query the AD to pull a list of email addresses and the usernames of those currently logged on users.

   if there is a stale dns record or the remote machine disconnects during the scripts execution (rare but it has happened during testing)
   an error will display to the console, but the script will continue to run normaly afterwards.

   please note you will need to change your domain name in the script to match your domain
#>

$datetime = Get-Date -f yyyy-MM-dd_HH-mm-ss
$parentDIR = "C:\temp"
$reachablefile = "$parentDIR\reachable-$datetime.csv"
$unreachablefile = "$parentDIR\unreachable-$datetime.csv"
$userlistfilepath = "$parentDIR\userlist-$datetime.csv"
$mailinglistfile = "$parentDIR\mailinglist-$datetime.csv"
$filteredfilepath = "$parentDIR\filtered-$datetime.csv"
function get-activeuser{
            
            Add-Type -AssemblyName System.Windows.Forms #adds the file browsing option
            
   
            $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog #opens a file broswer window
            $FileBrowser.Title = "Select File Containing list of machines (in csv format)"
            $FileBrowser.Filter = "Csv (*.csv)| *.csv"
            [void]$FileBrowser.ShowDialog()
            $FileBrowser.FileName
            
            $Hostnames = Import-Csv $FileBrowser.FileName -ErrorAction SilentlyContinue  | select -ExpandProperty "Hostname" 
            

            Write-Host "`nFound" -NoNewline; Write-Host "$($Hostnames.count)" -ForegroundColor Green -NoNewline; write-host "Entries."
            write-host "`n`n Filtering Online Hosts" -ForegroundColor Yellow

            Ping-Host $Hostnames
            
            $responded = get-content $reachablefile 
            
            write-host "`n$($responded.count) " -ForegroundColor Green -NoNewline; write-host "Machines are Online"
            
            write-host "`nGenerating Userlist" -ForegroundColor Yellow
            
            $userlist = Get-LoggedOnUser -ComputerName $responded -ErrorAction SilentlyContinue

            $userlist | Export-Csv $userlistfilepath

            Write-Host "`nDONE!`n" -ForegroundColor Green
            

           $csv = import-csv $userlistfilepath
           $filtered = @()
           $removenonactive = foreach($entry in $csv) {
           if($entry.UserName -ne "") {
           $filtered += $entry
           }
           }
$filtered | Export-Csv $filteredfilepath
foreach ($line in $filteredfilepath){
(Get-Content $filteredfilepath).replace('CONTOSO\', '') | Set-Content $filteredfilepath # replace contoso with your domain, but keep the \ character
}
$premail = import-csv $filteredfilepath
$mailarray = @()
foreach ($dname in $premail) { 
            $dname.UserName = Get-ADUser -Identity $dname.UserName -Properties mail | Select-Object -Property SamAccountName,mail 
            $mailarray += $dname
            }
$mailarray | Export-Csv $filteredfilepath

foreach ($line in $filteredfilepath){
(Get-Content $filteredfilepath).replace('"ComputerName","UserName"', '"ComputerName","UserName","Email"') | Set-Content $filteredfilepath
(Get-Content $filteredfilepath).replace('}', '') | Set-Content $filteredfilepath
(Get-Content $filteredfilepath).replace('@{', '') | Set-Content $filteredfilepath
(Get-Content $filteredfilepath).replace('SamAccountName=', '') | Set-Content $filteredfilepath
(Get-Content $filteredfilepath).replace(';', '"') | Set-Content $filteredfilepath
(Get-Content $filteredfilepath).replace('mail=', ',"') | Set-Content $filteredfilepath
}



            write-host "The Username and Emails users currently logged in is located at " -nonewline 
            write-host "$filteredfilepath" -ForegroundColor Green
            
            write-host "`n`nThe Userlist can be found at " -nonewline 
            write-host "$userlistfilepath" -ForegroundColor Yellow -NoNewline
            write-host " This list contains the hostnames/netbios names and the current active user (if applicable) (mainly for debugging if necessary)`n"
            write-host "log of failed hosts found at " -NoNewline
           
            write-host "$unreachablefile " -NoNewline -ForegroundColor Yellow
            Write-Host "(Hint: Use this next time for effiecency)" -ForegroundColor Magenta -NoNewline
            write-host " You will need to add a Hostname Header to this file though"

            write-host "`n`nNOTE:" -NoNewline -ForegroundColor yellow
            Write-Host " It is not unexpected for an error to occur regarding a specific machine name`n      this is usually the result of a stale dns record or the machine not responding the`n      second time when querying for the current user, do not worry"
            
            Remove-Item $reachablefile #this file simply contains the hostnames of all the machines in the userlist file, it's redundant and removed by default to avoid confusion            
       }
#credit for the ping-host function goes to Prateek Singh of https://geekeefy.wordpress.com/2015/07/16/powershell-fancy-test-connection/
#i've modified it to return an array and csv in most of my network scripts
Function Ping-Host
{
#Parameter Definition
Param
(
[Parameter(position = 0)] $Hosts,
[Parameter] $ToCsv
)
#Funtion to make space so that formatting looks good
Function Make-Space($l,$Maximum)
{
$space =””
$s = [int]($Maximum – $l) + 1
1..$s | %{$space+=” “}

return [String]$space
}
#write-host "Hostname" >> C:\temp\unreachable$($datetime).csv
#Array Variable to store length of all hostnames
$LengthArray = @()
$Hosts | %{$LengthArray += $_.length}

#Find Maximum length of hostname to adjust column witdth accordingly
$Maximum = ($LengthArray | Measure-object -Maximum).maximum
$Count = $hosts.Count

#Initializing Array objects
$Success = New-Object int[] $Count
$Failure = New-Object int[] $Count
$Total = New-Object int[] $Count
$reachable = @()
$unreachable = @()
cls
#Running a never ending loop
while($true){

$i = 0 #Index number of the host stored in the array
$out = “| HOST$(Make-Space 4 $Maximum)| STATUS| SUCCESS  | FAILURE  | ATTEMPTS  |”
$Firstline=””
1..$out.length|%{$firstline+=”_”}
If($Total[$i] -le $i){
#output the Header Row on the screen
Write-Host $Firstline
Write-host $out -ForegroundColor White -BackgroundColor Black

$Hosts|%{
$total[$i]++
If(Test-Connection $_ -Count 1 -Quiet -ErrorAction SilentlyContinue)
{
$success[$i]+=1
#Percent calclated on basis of number of attempts made
$SuccessPercent = $(“{0:N2}” -f (($success[$i]/$total[$i])*100))
$FailurePercent = $(“{0:N2}” -f (($Failure[$i]/$total[$i])*100))

#Print status UP in GREEN if above condition is met
Write-Host “| $_$(Make-Space $_.Length $Maximum)| UP$(Make-Space 2 4) | $SuccessPercent`%$(Make-Space ([string]$SuccessPercent).length 6) | $FailurePercent`%$(Make-Space ([string]$FailurePercent).length 6) | $($Total[$i])$(Make-Space ([string]$Total[$i]).length 9)|” -BackgroundColor Green
$reachable += $_ 
}
else
{

$Failure[$i]+=1

#Percent calclated on basis of number of attempts made
$SuccessPercent = $(“{0:N2}” -f (($success[$i]/$total[$i])*100))
$FailurePercent = $(“{0:N2}” -f (($Failure[$i]/$total[$i])*100))

#Print status DOWN in RED if above condition is met
Write-Host “| $_$(Make-Space $_.Length $Maximum)| DOWN$(Make-Space 4 4) | $SuccessPercent`%$(Make-Space ([string]$SuccessPercent).length 6) | $FailurePercent`%$(Make-Space ([string]$FailurePercent).length 6) | $($Total[$i])$(Make-Space ([string]$Total[$i]).length 9)|” -BackgroundColor Red
Write-Output $_ >> $unreachablefile
}
$i++
}

#Pause the loop for few seconds so that output
#stays on screen for a while and doesn’t refreshes

Start-Sleep -Seconds 1
write-host "Done Checking If Machines are online..."
return ,$reachable | Out-File $reachablefile
#$tempunreach = Get-Content C:\temp\unreachable-$($datetime).csv
#$tempunreach | Export-Csv -Path C:\temp\unreachable-$($datetime).csv 
} else { Break }

}

}
           # credit to Adam Bertram from
           #https://4sysops.com/archives/how-to-find-a-logged-in-user-remotely-using-powershell/
           #for his template
    function Get-LoggedOnUser
    {
        [CmdletBinding()]
        param
        (
             [Parameter()]
             [ValidateScript({ Test-Connection -ComputerName $_ -Quiet -Count 1 })]
             [ValidateNotNullOrEmpty()]
             [string[]]$ComputerName = $env:COMPUTERNAME
        )
        $counter = 0 
        foreach ($comp in $ComputerName)
        {
            $counter++
            Write-Progress -Activity "Processing Hosts" -CurrentOperation $comp -PercentComplete (($counter / $ComputerName.Count) * 100)
            Start-Sleep -Milliseconds 20
            $output = @{ 'ComputerName' = $comp }
            #
            $output.UserName = (Get-WmiObject -Class win32_computersystem -ComputerName $comp -ErrorAction SilentlyContinue).UserName
            [PSCustomObject]$output
         
        }
        return $output
    }

    get-activeuser
