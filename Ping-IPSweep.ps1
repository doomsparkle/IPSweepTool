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
            [array]$ipStart = $StartIP.IPAddresstoString.split("."); [array]$ipEnd = $EndIP.IPAddresstoString.split(".")
            if (($ipStart[0] -lt $ipEnd[0]) -or
            (($ipStart[0] -eq $ipEnd[0]) -and ($ipStart[1] -lt $ipEnd[1])) -or
            (($ipStart[0] -eq $ipEnd[0]) -and ($ipStart[1] -eq $ipEnd[1]) -and ($ipStart[2] -lt $ipEnd[2])) -or
            (($ipStart[0] -eq $ipEnd[0]) -and ($ipStart[1] -eq $ipEnd[1]) -and ($ipStart[2] -eq $ipEnd[2]) -and ($ipStart[3] -lt $ipEnd[3])))
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
        $MathIP1 = ([Int32]$ipStart[0] * [Math]::Pow(2, 24) + ([Int32]$ipStart[1] * [Math]::Pow(2, 16)) + ([Int32]$ipStart[2] * [Math]::Pow(2, 8)) + [Int32]$ipStart[3])
        $MathIP2 = ([Int32]$ipEnd[0] * [Math]::Pow(2, 24) + ([Int32]$ipEnd[1] * [Math]::Pow(2, 16)) + ([Int32]$ipEnd[2] * [Math]::Pow(2, 8)) + [Int32]$ipEnd[3])
        $Total = ($MathIP2 - $MathIP1) + 1

        # Start of our for loops because ranges for IPs
        for ([int32]$firstOct = $ipStart[0]; $firstOct -le $ipEnd[0]; $firstOct++)
        {
            if ($firstOct -eq $ipEnd[0])
            {
                [array]$ipEnd = $EndIP.IPAddresstoString.split(".")
            }
            [int32]$secOctBreak = 0
            for ([int32]$secOct = $ipStart[1]; ($secOct -le $ipEnd[1] -or $firstOct -lt $ipEnd[0]) -and [int32]$secOctBreak -eq 0; $secOct++)
            {
                if ($secOct -lt $ipEnd[1] -or $firstOct -lt $ipEnd[0])
                {
                    [int32]$ipEnd[2] = 255
                }
                if ($firstOct -lt $ipEnd[0])
                {
                    $ipEnd[1] = 256
                    if ($secOct -eq $ipEnd[1])
                    {
                        $secOct = 0
                        $ipStart[1] = 0
                        [int32]$secOctBreak++
                    }
                }
                $thirdOctBreak = 0
                for ([int32]$thirdOct = $ipStart[2]; ($thirdOct -le $ipEnd[2] -or $secOct -lt $ipEnd[1] -or $firstOct -lt $ipEnd[0]) -and $secOctBreak -eq 0 -and $thirdOctBreak -eq 0; $thirdOct++)
                {
                    if ($thirdOct -lt $ipEnd[2])
                    {
                        [int32]$ipEnd[3] = 255
                    }
                    elseif ($thirdOct -eq $ipEnd[2])
                    {
                        [array]$ipEnd = $EndIP.IPAddresstoString.split(".")
                    }
                    elseif (($secOct -lt $ipEnd[1] -or $firstOct -lt $ipEnd[0]) -and $thirdOct -eq 256)
                    {
                        $thirdOct = 0
                        $ipStart[2] = 0
                        $thirdOctBreak++
                    }
                    $fourthOctBreak = 0
                    for ([int32]$fourthOct = $ipStart[3]; ($fourthOct -le $ipEnd[3] -or $thirdOct -lt $ipEnd[2] -or $secOct -lt $ipEnd[1] -or $firstOct -lt $ipEnd[0]) -and $thirdOctBreak -eq 0 -and $fourthOctBreak -eq 0; $fourthOct++)
                    {
                        $ping = New-Object System.Net.NetworkInformation.Ping
                        $result = $ping.Send("$firstOct.$secOct.$thirdOct.$fourthOct", 500)

                        if ($ResolveDNS)
                        {
                            if ($ping.Status -eq "Success")
                            {
                                $dns = [System.Net.DNS]::GetHostEntry($ping.Address)
                            }
                        }

                        $IPCompleted = New-Object PSObject -Property @{IPAddress = "$firstOct.$secOct.$thirdOct.$fourthOct"; PingStatus = $result.Status; TripTime = $result.RoundtripTime; Hostname = $dns.HostName}
                        $IPTable += $IPCompleted
                        $ProgressBar = $Count / $Total
                        $ProgressBar *= 100
                        $ProgressBar = [Math]::Truncate($ProgressBar)
                        Write-Progress -Activity "Performing Actions. Please Wait." -Status "$ProgressBar% Complete" -PercentComplete $ProgressBar -currentoperation "$firstOct.$secOct.$thirdOct.$fourthOct"
                        $Count++

                        [array]$ipEnd = $EndIP.IPAddresstoString.Split(".")

                        if ($thirdOct -lt $ipEnd[2] -or $secOct -lt $ipEnd[1] -or $firstOct -lt $ipEnd[0])
                        {
                            if ($fourthOct -eq 255)
                            {
                                $fourthOct = 1
                                $ipStart[3] = 1
                                $fourthOctBreak++
                            }
                        }
                    }
                }
            }
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