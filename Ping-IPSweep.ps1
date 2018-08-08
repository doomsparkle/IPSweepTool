function Ping-IPSweep {
    [CmdletBinding()]
    param (

        # IPv4 Address where you want to start your sweep
        [Parameter(Mandatory=$true,
        Position=0,HelpMessage="Provide a starting IPv4 Address.")]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [IPAddress][ValidatePattern("^([1-9]{1,3}|[0-9]{2,}).([0-9]{1,3}).([0-9]{1,3}).([1-9]{1,3}|[0-9]{2,})$")]
        $StartIP

        # IPv4 Address where you want to end your sweep
        [Parameter(Mandatory=$true,
        Position=0,HelpMessage="Provide a ending IPv4 Address.")]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [IPAddress][ValidatePattern("^([1-9]{1,3}|[0-9]{2,}).([0-9]{1,3}).([0-9]{1,3}).([1-9]{1,3}|[0-9]{2,})$")]
        [IPAddress]$EndIP

        [bool]$ResolveDNS

        [string]$SaveOutput

    )

    begin {

    }

    process {

    }

    end {

    }
}

$ErrorActionPreference = "SilentlyContinue"; $error.Clear(); $StartIP,$EndIP= $null; $ErrCheck = 0
$count = 1; $IPTable = @(); $SaveCheck = 0; $SaveFile = $null; $DNSCheck = 0; $DNSReq = $null
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
$userprofile = $(Get-ChildItem env:\USERPROFILE).value
[regex]$valid = "^([1-9]{1,3}|[0-9]{2,}).([0-9]{1,3}).([0-9]{1,3}).([1-9]{1,3}|[0-9]{2,})$"

while ($SaveCheck -eq 0)
{
        $SaveFilePrompt = Read-Host "Would you like to save the output to a file? (y/n)"
        if ($SaveFilePrompt -eq "n")
        {
            $SaveFile = $false
            $SaveCheck++
        }
        elseif ($SaveFilePrompt -eq "y")
        {
            $SaveFile = $true
            $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
            $SaveFileDialog.InitialDirectory = "$userprofile\Desktop"
            $SaveFileDialog.Title = "Save As"
            $SaveFileDialog.DefaultExt = "csv"
            $SaveFileDialog.Filter = "CSV files (*.csv)|*.csv|Text files (*.txt)|*.txt|All files (*.*)|*.*"
            $SaveFileDialog.ShowHelp = $true
            $SaveFileDialog.ShowDialog() | Out-Null
            $OutputFile = $SaveFileDialog.Filename
            $SaveCheck++
        }
        else
        {
            Write-Warning "Please enter 'y' or 'n'."
            $SaveFilePrompt = $null
        }
}

while ($DNSCheck -eq 0)
{
    $DNSRequestPrompt = Read-Host "Would you like to lookup the hostname even if the host is dead? (y/n)"
    if ($DNSRequestPrompt -eq "n")
    {
        $DNSReq = $false
        $DNSCheck++
    }
    elseif ($DNSRequestPrompt -eq "y")
    {
        $DNSReq = $true
        $DNSCheck++
    }
    else
    {
        Write-Warning "Please enter 'y' or 'n'."
        $DNSRequestPrompt = $null
    }
}

while ($ErrCheck -eq 0)
{
    while ($StartIP -eq $null)
    {
        [ipaddress]$StartIP = Read-Host "Please input the first IP address you would like to scan: "
        $error[0].exception; $error.Clear()
        $input1 = $StartIP.IPAddressToString
        if ($input1 -notmatch $valid)
        {
            Write-Error "Cannot convert value `"$input1`" to type `"System.Net.IPAddress.`" Error: An invalid IP address was specified."
            $StartIP = $null
        }
    }
    while ($EndIP -eq $null)
    {
        [ipaddress]$EndIP = Read-Host "Please input the IP address you want to finish the scan: "
        $error[0].exception; $error.Clear()
        $input2 = $EndIP.IPAddressToString
        if ($input2 -notmatch $valid)
        {
            Write-Error "Cannot convert value `"$input2`" to type `"System.Net.IPAddress.`" Error: An invalid IP address was specified."
            $EndIP = $null
        }
    }

    [array]$ip1 = $StartIP -split ".",0,"simplematch"; [array]$ip2 = $EndIP -split ".",0,"simplematch"
    if (($ip1[0] -lt $ip2[0]) -or
    (($ip1[0] -eq $ip2[0]) -and ($ip1[1] -lt $ip2[1])) -or
    (($ip1[0] -eq $ip2[0]) -and ($ip1[1] -eq $ip2[1]) -and ($ip1[2] -lt $ip2[2])) -or
    (($ip1[0] -eq $ip2[0]) -and ($ip1[1] -eq $ip2[1]) -and ($ip1[2] -eq $ip2[2]) -and ($ip1[3] -lt $ip2[3])))
    {
        $ErrCheck++
    }
    else
    {
        Write-Error "An invalid IP address range was specified."
        $StartIP,$EndIP = $null
    }
}

[array]$ip1 = $StartIP -split ".",0,"simplematch"; [array]$ip2 = $EndIP -split ".",0,"simplematch"

$MathIP1 = ([Int32]$ip1[0] * [Math]::Pow(2, 24) + ([Int32]$ip1[1] * [Math]::Pow(2, 16)) + ([Int32]$ip1[2] * [Math]::Pow(2, 8)) + [Int32]$ip1[3])
$MathIP2 = ([Int32]$ip2[0] * [Math]::Pow(2, 24) + ([Int32]$ip2[1] * [Math]::Pow(2, 16)) + ([Int32]$ip2[2] * [Math]::Pow(2, 8)) + [Int32]$ip2[3])
$Total = ($MathIP2 - $MathIP1) + 1

for ([int]$a = $ip1[0];($a -le $ip2[0]); $a++)
{
    if ($a -eq $ip2[0])
    {
        [array]$ip2 = $EndIP -split ".",0,"simplematch"
    }
    [int]$brakeB = 0
    for ([int]$b = $ip1[1];($b -le $ip2[1] -or $a -lt $ip2[0]) -and [int]$brakeB -eq 0; $b++)
    {
        if ($b -lt $ip2[1] -or $a -lt $ip2[0])
        {
            [int]$ip2[2] = 255
        }
        if ($a -lt $ip2[0])
        {
            $ip2[1] = 256
            if ($b -eq $ip2[1])
            {
                $b = 0
                $ip1[1] = 0
                [int]$brakeB++
            }
        }
        $brakeC = 0
        for ([int]$c = $ip1[2];($c -le $ip2[2] -or $b -lt $ip2[1] -or $a -lt $ip2[0]) -and $brakeB -eq 0 -and $brakeC -eq 0; $c++)
        {
            if ($c -lt $ip2[2])
            {
                [int]$ip2[3] = 255
            }
            elseif ($c -eq $ip2[2])
            {
                [array]$ip2 = $EndIP -split ".",0,"simplematch"
            }
            elseif ($b -lt $ip2[1] -or $a -lt $ip2[0])
            {
               if ($c -eq 256)
               {
                   $c = 0
                   $ip1[2] = 0
                   $brakeC++
               }
            }
            $brakeD = 0
            for ([int]$d = $ip1[3];($d -le $ip2[3] -or $c -lt $ip2[2] -or $b -lt $ip2[1] -or $a -lt $ip2[0]) -and $brakeC -eq 0 -and $brakeD -eq 0; $d++)
            {
                $ping = (New-Object System.Net.NetworkInformation.Ping).Send("$a.$b.$c.$d", 5, 64)

                if ($DNSReq -eq $false)
                {
                    $dns = if ($ping.Status -eq "Success") {[System.Net.DNS]::GetHostEntry($ping.Address)}
                }
                else
                {
                    $dns = [System.Net.DNS]::GetHostEntry("$a.$b.$c.$d")
                }

                $IPCompleted = New-Object PSObject -Property @{IPAddress = "$a.$b.$c.$d"; PingStatus = $ping.Status; TripTime = $ping.RoundtripTime; Hostname = $dns.HostName}
                $IPTable += $IPCompleted
                $ProgressBar = $Count / $Total
                $ProgressBar *= 100
                $ProgressBar = [Math]::Truncate($ProgressBar)
                Write-Progress -Activity "Performing Actions. Please Wait." -Status "$ProgressBar% Complete" -PercentComplete $ProgressBar -currentoperation "$a.$b.$c.$d"
                $count++

                [array]$ip2 = $EndIP -split ".",0,"simplematch"

                if ($c -lt $ip2[2] -or $b -lt $ip2[1] -or $a -lt $ip2[0])
                {
                    if ($d -eq 255)
                    {
                        $d = 1
                        $ip1[3] = 1
                        $brakeD++
                    }
                }
            }
        }
    }
}

if ($SaveFile -eq $true)
{
    $IPTable | Select-Object IPAddress, HostName, PingStatus, TripTime | Export-CSV $OutputFile -UseCulture -NoTypeInformation -NoClobber
}
else
{
    $IPTable | Select-Object IPAddress, HostName, PingStatus, TripTime | Format-Table -Auto
}
