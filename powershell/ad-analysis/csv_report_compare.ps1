<# Created by: Shadexic
   Created on: 12-07-2021
   Version   : 1.0
   Description: Import a list of users and filter out all entries that are less than a year old.
   then import a second list of entries and find all the matching entries between the two and generate a CSV of the matches
   originally designed for a list of API tokens and assisting with the identification of stale  items.
#>

#prep files
$revokable= "C:\temp\revokable-$(Get-Date -f yyyy-MM-dd_HH-mm-ss).csv"
$datetime = Get-Date -f yyyy-MM-dd_HH-mm-ss

#load modules needed for the two files and display custom prompt for each window


Add-Type -AssemblyName System.Windows.Forms #adds the file browsing option
            $FileBrowser1 = New-Object System.Windows.Forms.OpenFileDialog #opens a file broswer window
            $FileBrowser1.Title = "Please Select the first File"
            $FileBrowser1.Filter = "Csv (*.csv)| *.csv"
            [void]$FileBrowser1.ShowDialog()
            #$FileBrowser1.FileName # uncomment this line if you wish to see the path for the first file displayed to the console
            $report = Import-Csv $FileBrowser1.FileName

            $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog #opens a file broswer window
            $FileBrowser.Title = "Please Select the Second File"
            $FileBrowser.Filter = "Csv (*.csv)| *.csv"
            [void]$FileBrowser.ShowDialog()
            # $FileBrowser.FileName # uncomment this line if you wish to see the path for the second file displayed to the console
            $tokenlist = Import-Csv $FileBrowser.FileName
                        

#get todays date and minus 12 months and format it to match the imported report
$lastyear = (get-date).AddMonths(-12).ToString('yyy-MM-dd HH:mm')

#initialise the first array
$torevoke = @()

#loop through each item in the first report and identify all records that are more than a year old
foreach ($entry in $report) {
if ($entry.'Authentication Time' -lt $lastyear) {
$torevoke += ,$entry
}
}

#initialize the second array
$A = @()

#loop through each report and store the matches in the $A array
foreach ($entry in $torevoke) {
if ($tokenlist."Token ID" -contains $entry."Token ID") {
$A += $entry } }

#Export the csv report to the pathway specified at the beginning
$A | Export-Csv $revokable

# "Fancy" output to provide metrics on original file and rinal report along with location of the final report
Write-Host "There are " -nonewline
write-host "$($torevoke.Count) " -ForegroundColor Cyan -NoNewline
write-host "Tokens that are more than a year old in the original report`n`n"

Write-Host "There are " -nonewline
write-host "$($A.Count) " -ForegroundColor Red -NoNewline
write-host "Tokens listed in the original report that are still active`n`n"

write-host "The report of Tokens to Revoke is located at " -NoNewline
Write-Host "$revokable" -ForegroundColor Yellow 

