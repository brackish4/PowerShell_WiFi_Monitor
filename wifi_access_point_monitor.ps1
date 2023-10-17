
# Author: David Barron
# Date: 10/17/2023

# PowerShell Script to check the BSSID and Signal Strength of the Current Wi-Fi Access Point.
# The script can be customized to: 
#   - Check for AP changes at specified intervals.
#   - Push a custom pop-up notification in Windows.
#   - Create a JSON file with each AP and signal strength with a timestamp.

# Initialize $results to hold information on AP and changes. 
$results = @()

# Get the BSSID (MAC address) of the current AP.
$cur_ap=(netsh wlan show interfaces) -Match '^\s+BSSID' -Replace '^\s+BSSID\s+:\s+','' | Out-String -NoNewline

#$Time = (Get-Date -UFormat "%A %B/%d/%Y %T %Z")

$hostname = HOSTNAME.EXE

# Check current BSSID
$cur_ap

# Modify time before next check after beginning.
Start-Sleep -Seconds 10

# Get an updated reading on connected Access Point
$check_ap=(netsh wlan show interfaces) -Match '^\s+BSSID' -Replace '^\s+BSSID\s+:\s+','' | Out-String -NoNewline


# CHECK CURRENT AP AGAINST PREVIOUS. Push POP-UP NOTIFICATION if condition is met.
# For testing purposes it is helpful to use '-eq' to show that the AP has NOT changed.
if ($cur_ap.Replace('%','') -eq $check_ap) # This line will check if AP is the SAME! Uncomment the line below to check for changes!
# if ($cur_ap.Replace('%','') -ne $check_ap)    # Check if '-ne' for NOT EQUAL to show a connection to a new AP.
{
    Add-Type -AssemblyName System.Windows.Forms
    $global:balmsg = New-Object System.Windows.Forms.NotifyIcon # Pop-up notification on Windows Desktop.
    $path = (Get-Process -id $pid).Path
    $balmsg.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path) # This could also be something like "$($ENV:windir)\notepad.exe"
    $balmsg.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Error # or ::Info etc.
    $balmsg.BalloonTipText = “The Wi-Fi AP IS $cur_ap `nThis would be helpful if it changed!” # Customize this message.
    $balmsg.BalloonTipTitle = "Attention $Env:USERNAME"
    $balmsg.Visible = $true
    $balmsg.ShowBalloonTip(10000)
}


# Create a hash table in a custom PS object. Hostname, AP BSSID, AP Signal Strength, Timestamp
$wifiInfo = New-Object psobject -Property @{
    ComputerName = $hostname
    CurrentAP = $cur_ap
    SignalStrength = ($cur_strength=(netsh wlan show interfaces) -Match '^\s+Signal' -Replace '^\s+Signal\s+:\s+','' | Out-String -NoNewline)
    TimeStamp = (Get-Date)
}

$results += $wifiInfo # Append $wifiInfo object to the $results list. 

# Access properties of the hashable object:
$wifiInfo.ComputerName

# Test to see if the custom PS object is added to the $results list each time.
#$results += $wifiInfo
#$results += $wifiInfo
#$results | ConvertTo-Json

# TO-DO: Loop this next part for continual checks.

Start-Sleep -Seconds 30 # Change this for the desired interval to poll for AP changes. 

$currentTime = Get-Date # New timestamp to compare against previous timestamp.
if ($wifiInfo.TimeStamp -ne $currentTime) {
    Write-Host "TIME CHANGED." # Not needed. Comment out.
    $wifiInfo = New-Object psobject -Property @{
        ComputerName = $hostname
        CurrentAP = $check_ap
        SignalStrength = ($cur_strength=(netsh wlan show interfaces) -Match '^\s+Signal' -Replace '^\s+Signal\s+:\s+','' | Out-String -NoNewline)
        TimeStamp = (Get-Date)
        AP_Changed = $true # Add new boolean key to show AP has changed.
    }
    $results += $wifiInfo # Append new Wi-Fi AP info.
}
Else {
    Time.Start-Sleep -Seconds 30 # Sleep again before next check.
}


Write-Host "NEW INFO: `n " -ForegroundColor DarkYellow

# Convert the hashable object to JSON format and save to JSON file.
$results | ConvertTo-Json -Depth 4 | Out-File .\wifi_info.json

# This is how you could read in the JSON and print in PowerShell terminal.
$readJson = Get-Content .\wifi_info.json
$readJson | Write-Host -ForegroundColor DarkGreen



# ANOTHER example of a pop-up notification
#[reflection.assembly]::loadwithpartialname('System.Windows.Forms')
#[reflection.assembly]::loadwithpartialname('System.Drawing')
#$notify = new-object system.windows.forms.notifyicon
#$notify.icon = [System.Drawing.SystemIcons]::Information
#$notify.visible = $true
#$notify.showballoontip(10000,'WI-FI CHECK','Hey look at me!!',[system.windows.forms.tooltipicon]::Info)