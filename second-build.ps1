function generate-IP ($currentIP) {
    
    $position = 3
    $correctPosition = $null

    while ($correctPosition -eq $null){

        if ($currentIP[$position] -lt 255){
            $currentIP[$position]++

            if ($position -eq 3){
                $correctPosition = "Not null"
            }

            else{
                $position = 3 
            }
        }

        else {
            $position--
            $currentIP[($position + 1)] = 0
        }
    }
}

function ping-sweep ($currentIP) {
    $ping = New-Object System.Net.NetworkInformation.Ping
    $result = $ping.Send("$($currentIP[0]).$($currentIP[1]).$($currentIP[2]).$($currentIP[3])", 500)
    write-host "Pingin some shit $($currentIP[0]).$($currentIP[1]).$($currentIP[2]).$($currentIP[3])"
     if ($ResolveDNS){
                            
        if ($ping.Status -eq "Success"){
            $dns = [System.Net.DNS]::GetHostEntry($ping.Address)
            }
        } 
    $IPCompleted = New-Object PSObject -Property @{IPAddress = "$($currentIP[0]).$($currentIP[1]).$($currentIP[2]).$($currentIP[3])"; PingStatus = $result.Status; TripTime = $result.RoundtripTime; Hostname = $dns.HostName}
    $IPCompleted
}

function Ping-IPSweep {
    [CmdletBinding()]
    param (

        # IPv4 Address where you want to start your sweep
        [Parameter(Mandatory=$true,Position=0,HelpMessage="Provide a starting IPv4 Address.")]
        [ValidateNotNullOrEmpty()]
        [IPAddress][ValidatePattern("^([1-9]{1,3}|[0-9]{2,}).([0-9]{1,3}).([0-9]{1,3}).([1-9]{1,3}|[0-9]{2,})$")]$StartIP,

        # IPv4 Address where you want to end your sweep
        [Parameter(Mandatory=$true,Position=1,HelpMessage="Provide a ending IPv4 Address.")]
        [ValidateNotNullOrEmpty()]
        [IPAddress][ValidatePattern("^([1-9]{1,3}|[0-9]{2,}).([0-9]{1,3}).([0-9]{1,3}).([1-9]{1,3}|[0-9]{2,})$")]$EndIP,

        [switch]$ResolveDNS,

        [switch]$SaveOutput

    )
    begin {
        $error.Clear(); $ErrCheck = 0; $Count = 1; $IPTable = @();
        while ($ErrCheck -eq 0)
        {
            [array]$startingIP = $StartIP.IPAddresstoString.split("."); [array]$finishingIP = $EndIP.IPAddressToString.split(".")
            [int[]]$currentIP = $startingIP; [int[]]$finishIP = $finishingIP;
            if (($currentIP[0] -lt $finishIP[0]) -or
            (($currentIP[0] -eq $finishIP[0]) -and ($currentIP[1] -lt $finishIP[1])) -or
            (($currentIP[0] -eq $finishIP[0]) -and ($currentIP[1] -eq $finishIP[1]) -and ($currentIP[2] -lt $finishIP[2])) -or
            (($currentIP[0] -eq $finishIP[0]) -and ($currentIP[1] -eq $finishIP[1]) -and ($currentIP[2] -eq $finishIP[2]) -and ($currentIP[3] -lt $finishIP[3])))
            {
                $ErrCheck++
            }
            else
            {
                Write-Error "An invalid IP address range was specified."
                break
            }
        }
    }
    process {
        # Math for our Progress Bar. Calculates the Number of IPs between Start and End to populate $total.
        $MathIP1 = ([Int32]$currentIP[0] * [Math]::Pow(2, 24) + ([Int32]$currentIP[1] * [Math]::Pow(2, 16)) + ([Int32]$currentIP[2] * [Math]::Pow(2, 8)) + [Int32]$currentIP[3])
        $MathIP2 = ([Int32]$finishIP[0] * [Math]::Pow(2, 24) + ([Int32]$finishIP[1] * [Math]::Pow(2, 16)) + ([Int32]$finishIP[2] * [Math]::Pow(2, 8)) + [Int32]$finishIP[3])
        $Total = ($MathIP2 - $MathIP1) + 1
        
        while ((($currentIP[0] -lt $finishIP[0]) -or
        (($currentIP[0] -eq $finishIP[0]) -and ($currentIP[1] -lt $finishIP[1])) -or
        (($currentIP[0] -eq $finishIP[0]) -and ($currentIP[1] -eq $finishIP[1]) -and ($currentIP[2] -lt $finishIP[2])) -or
        (($currentIP[0] -eq $finishIP[0]) -and ($currentIP[1] -eq $finishIP[1]) -and ($currentIP[2] -eq $finishIP[2]) -and ($currentIP[3] -lt $finishIP[3])))){


        generate-IP($currentIP)
        $morecurrenterIP = $currentIP[0], $currentIP[1], $currentIP[2], ($currentIP[3] - 1)
        $IPTable += ping-sweep($morecurrenterIP)
        #write-host "$($currentIP[0]).$($currentIP[1]).$($currentIP[2]).$($currentIP[3] - 1)"

        if ($currentIP[3] -eq 255){
            #write-host "$($currentIP[0]).$($currentIP[1]).$($currentIP[2]).$($currentIP[3])"
            $IPTable += ping-sweep($currentIP)
            $Count++
        }

        elseif (($currentIP[0] -eq $finishIP[0]) -and ($currentIP[1] -eq $finishIP[1]) -and ($currentIP[2] -eq $finishIP[2]) -and ($currentIP[3] -eq $finishIP[3])){
            #write-host "$($currentIP[0]).$($currentIP[1]).$($currentIP[2]).$($currentIP[3])"
            $IPTable += ping-sweep($currentIP)
            $Count++
        }
        $ProgressBar = $Count / $Total
        $ProgressBar *= 100
        $ProgressBar = [Math]::Truncate($ProgressBar)
        Write-Progress -Activity "Performing Actions. Please Wait." -Status "$ProgressBar% Complete" -PercentComplete $ProgressBar -currentoperation "$($currentIP[0]).$($currentIP[1]).$($currentIP[2]).$($currentIP[3])"
        $Count++
        }
    }
    end {
         if ($SaveOutput)
        {
            $IPTable | Select-Object IPAddress, HostName, PingStatus, TripTime | Export-CSV $OutputFile -UseCulture -NoTypeInformation -NoClobber
        }
        else
        {
            $IPTable | Select-Object IPAddress, HostName, PingStatus, TripTime | Format-Table -Auto
        }
        
    }
}
Ping-IPSweep