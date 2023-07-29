### Checking CPU temperature
# StackOverflow help on WMI and getting CPU temperature:
#   https://stackoverflow.com/questions/39738494/get-cpu-temperature-in-cmd-power-shell
# PS5.1 - Admin

function Get-CPUTemperature {
    <#
    .SYNOPSIS
        Get the CPU temperature of the current machine.
    .DESCRIPTION
        Get the CPU temperature of the current machine.
        Must be run in Windows PowerShell 5.1 (non-core) as it uses WMI.
        Requires admin rights.
    .PARAMETER Loop
        Continuously loop and output the temperature every $LoopSeconds.
    .PARAMETER LoopSeconds
        The number of seconds to wait between each loop (defaults to 30s).
    .EXAMPLE    
        Get-CPUTemperature
        54C || 0C || 43C
    .EXAMPLE
        Get-CPUTemperature -Loop
        20:01:03: 56C || 0C || 43C
        20:01:33: 56C || 0C || 43C
        20:02:03: 56C || 0C || 43C
        Ctrl+C
    .EXAMPLE
        Get-CPUTemperature -Loop -LoopSeconds 10
        20:02:16: 56C || 0C || 43C
        20:02:26: 55C || 0C || 43C
        20:02:36: 56C || 0C || 43C
        20:02:46: 56C || 0C || 43C
        Ctrl+C
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Loop = $false,

        [Parameter(Mandatory = $false)]
        [int]$LoopSeconds = 30
    )

    if ($DebugPreference -eq "Inquire"){
        $DebugPreference = "Continue"
        Write-Debug "Overriding Windows PowerShell default (`"Inquire`"): DebugPreference = $DebugPreference"
    }

    Write-Debug "Loop: $Loop"
    Write-Debug "LoopSeconds: $LoopSeconds"

    # Ensure a non-core version of PowerShell is being used.
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        Write-Error "This function requires PowerShell 5.1 (non-core) for WMI to work."
        return
    }

    # Ensure the script is running as an administrator.
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This function requires admin rights to run."
        return
    }

    # Loop until the user presses Ctrl+C or break the loop if $Loop is not set.
    while ($true) {
        $Temperatures = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi"
        $TemperaturesShow = ""

        foreach ($CurrentTemperature in $Temperatures.CurrentTemperature)
        {
            $TemperatureCelsius = [Math]::Round(($CurrentTemperature / 10) - 273)
            $TemperaturesShow = $TemperaturesShow + "${TemperatureCelsius}C || "
        }

        if (-not($Loop)) {
            Write-Output "$($TemperaturesShow -Replace " \|\| $"," ") "
            break
        }

        Write-Output "$(Get-Date -Format "HH:mm:ss"): $($TemperaturesShow -Replace " \|\| $"," ") "
        Start-Sleep -Seconds $LoopSeconds
    }

    return
}
