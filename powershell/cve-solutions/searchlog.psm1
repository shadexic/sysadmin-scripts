function searchlog
{
    param (
    [Parameter(Mandatory=$true)]
    [string]$logname,
    [string]$eventid)
    
    if ($logname -eq "nightmare") {
    try {
    $ret = Get-WinEvent -FilterHashtable @{Logname="Microsoft-Windows-PrintService/Operational"; id=307} -ErrorAction Stop
    Write-Host "Found 307 Events" -ForegroundColor yellow }
    catch [System.Exception] { write-host "No 307 Jobs Found" -ForegroundColor Green} 
    }

    else{

    try {
    $ret = get-winevent -FilterHashtable @{Logname=$logname;id=$eventid} -ErrorAction Stop

    Write-Host "some $eventid's found" -ForegroundColor yellow
    } catch [System.Exception]  { Write-Host "no $eventid events" -ForegroundColor Green }
    }
    <#
        .NOTES
        Version:       1.1
        Author:        shadexic
        Created on:    2021-07-07
        notes:         for print nightmare but made for other logs
                       no return value for automation yet, only visual feedback


        .SYNOPSIS
        Searches supplied eventlog for supplied eventid.

        .DESCRIPTION
        Searches eventviewerlogs for specified eventid.
        Originally Created to search for job 307 during Print Nightmare.

        .PARAMETER logname
        Specifies the event log.
        Use "nightmare" to search for 307 in the PrintServices/Operational.

        .PARAMETER eventid
        Specifies the eventid.

        .INPUTS
        None. You cannot pipe objects to searchlog.

        .OUTPUTS
        System.String. searchlog returns a string with the result of the query.

        .EXAMPLE
        PS> searchlog -logname Microsoft-Windows-PrintService/Operational
        There are 307's present

        .EXAMPLE
        PS> searchlog -logname Microsoft-Windows-PrintService/Operational -eventid 307
        There are 307's present 

        .EXAMPLE
        PS> searchlog Microsoft-Windows-PrintService/Operational 123
        There are no 123's present

        .EXAMPLE
        PS> lsearchlog nightmare
        There are no 307's present

        .EXAMPLE
        PS> searchlog nightmare
        Found 307 jobs

        .LINK
        https://github.com/shadexic/powershell/blob/main/admin/searchlog.psm1

        .LINK
        Get-WinEvent
    #>
}
