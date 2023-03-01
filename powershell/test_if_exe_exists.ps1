<#
Script Name: Test remote exe path
Author: shadexic
Created: July 2nd 2021
Revised on and by:
Description:
This script will prompt the user for the hostname (will work without the "fqdn" of the domain) and will check the directory
specified on line 23 (or in the while statement) for any .exe files (this can also search for a specific file, simply change the path)
this was originally written for assisting with monitoring the uninstallation process of a remote program that would only start
to progress after the .exe files were removed by said uninstallation process and will check every 45 seconds until
the directory does not contain any .exe files, at such time it will print a green text line indicating the files are no longer present.

the script is written in such a way that it can be run through the ISE as a copy and pasted version.
#>

$remotemachine = read-host "Enter the hostname of the remote PC"

$exe = "*.exe"

function test-if-exe-exists
{
    $int = 2
    while( Test-Path "\\$remotemachine\C$\Program Files (x86)\YOUR_DIRECTORY_HERE") #while automatically defaults to true if not specified
    {
    write-host "There are still exe files located in the directory of $remotemachine" -ForegroundColor Yellow
    write-host "Will check again in 45 seconds"
    Start-Sleep -Seconds 45 #so as not to check every time the test-path ends and generating unecessary traffic.
    }
    Write-Host "There are no exe files located in the \YOUR_DIRECTORY_HERE of $remotemachine" -ForegroundColor Green #this line only prints once the files are gone. as it means that the while loop is done
}

test-if-exe-exists