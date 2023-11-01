Import-Module -Name BitsTransfer

function ConvertTo-MP4andTransferToServer {
    <#
    .SYNOPSIS
        Convert large MKV to MP4 and transfer to server.
    .DESCRIPTION
        Convert large MKV to MP4 and transfer to a new location.
        Requires HandBrake CLI to be installed.
          Reference: https://handbrake.fr/docs/en/1.6.0/cli/command-line-reference.html
        Progress bar on copy uses Bits Transfer module.
          Reference: https://stackoverflow.com/questions/2434133/progress-during-large-file-copy-copy-item-write-progress
    .PARAMETER Path
        String. The path to the MKV file to convert.
    .PARAMETER Destination
        String. The destination directory to transfer the MP4 file to.
    .PARAMETER Loop
        Switch. Optional switch to continuously loop.
    .EXAMPLE
        $ ConvertTo-MP4andTransferToServer -Path "C:\Users\${env:USERNAME}\Videos\MakeMKV\Home Videos S04*.mkv" -Destination "\\Server\Videoes\Home Videos\Series 4"
        19:25:11: TITLE: Home Videos S04 E11
        & C:\Program Files\HandBrake\HandBrakeCLI\HandBrakeCLI.exe -i C:\Users\User\Videos\MakeMKV\Home Videos S04 E11.mkv -o C:\Users\User\Videos\MakeMKV\Home Videos S04 E11.mp4 --preset "Fast 1080p30"
        . . .
        19:32:20: Moving original MKV to Done: C:\Users\User\Videos\MakeMKV\Home Videos S04 E11.mkv
        19:32:20: Start-BitsTransfer -Source C:\Users\User\Videos\MakeMKV\Home Videos S04 E11.mp4 -Destination \\Server\Videoes\Home Videos\Series 4 -DisplayName 'Transfer video file' -Description 'Transfer Video File..'
        19:33:05: Moving converted MP4 to Done: C:\Users\User\Videos\MakeMKV\Home Videos S04 E11.mp4
        19:33:05: Start-Sleep -Seconds 900 (Next kick-off: 19:48:05)
    .EXAMPLE
        $ ConvertTo-MP4andTransferToServer -Path "C:\Users\${env:USERNAME}\Videos\MakeMKV\Wedding*.mkv" -Destination "\\Server\Home Movies"
        19:25:11: TITLE: Wedding Day
        & C:\Program Files\HandBrake\HandBrakeCLI\HandBrakeCLI.exe -i C:\Users\User\Videos\MakeMKV\Wedding Day.mkv -o C:\Users\User\Videos\MakeMKV\Wedding Day.mp4 --preset "Fast 1080p30"
        . . .
        19:32:20: Moving original MKV to Done: C:\Users\User\Videos\MakeMKV\Wedding Day.mkv
        19:32:20: Start-BitsTransfer -Source C:\Users\User\Videos\MakeMKV\Wedding Day.mp4 -Destination \\Server\Videoes\Home Videos\Series 4 -DisplayName 'Transfer video file' -Description 'Transfer Video File..'
        19:33:05: Moving converted MP4 to Done: C:\Users\User\Videos\MakeMKV\Wedding Day.mp4
        19:33:05: Start-Sleep -Seconds 900 (Next kick-off: 19:48:05)
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,

        [Parameter(Mandatory = $false)]
        [int]$SleepBetweenTasks = 900, # 15 minutes (let CPU cool down)

        [Parameter(Mandatory = $false)]
        [switch]$Loop
    )
    Write-Debug "$(Get-Date -Format "HH:mm:ss"): Path: $Path"
    Write-Debug "$(Get-Date -Format "HH:mm:ss"): Destination: $Destination"
    Write-Debug "$(Get-Date -Format "HH:mm:ss"): SleepBetweenTasks: $SleepBetweenTasks"
    Write-Debug "$(Get-Date -Format "HH:mm:ss"): Loop: $Loop"
    
    # $SleepBetweenTasks  = 900 # 15 minutes (let CPU cool down)
    $SleepBetweenChecks = 30  # 30 seconds
    $HandBrakeCliExe = "C:\Program Files\HandBrake\HandBrakeCLI\HandBrakeCLI.exe"

    # Check that necessary files and folders exist.
    if ([string]::IsNullOrWhiteSpace($Path)) {
        Write-Error "Path is null or empty."
        return
    }
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Path does not exist: $Path"
        return
    }
    if ([string]::IsNullOrWhiteSpace($Destination)) {
        Write-Error "Destination is null or empty."
        return
    }
    if (-not (Test-Path -Path $Destination)) {
        CreateDestinationFolderAsNecessary -Destination $Destination        
        if (-not (Test-Path -Path $Destination)) {
            Write-Error "Destination does not exist: $Destination"
            return
        }
    }
    if (-not (Test-Path -Path $HandBrakeCliExe)) {
        Write-Error "HandBrake CLI is null or empty."
        return
    }

    do {
        $Item = Get-Item -Path $Path | Sort-Object -Property LastWriteTime | Select-Object -First 1
        $ItemTitle = $Item.BaseName
        $ItemFullName = $Item.FullName
        $ItemDirectoryName = $Item.DirectoryName
        $ItemDoneDirectory = "${ItemDirectoryName}\Done"

        if ($null -ne $ItemTitle) {
            Write-Host "$(Get-Date -Format "HH:mm:ss"): TITLE: $ItemTitle" -ForegroundColor Green
            Write-Host "& $HandBrakeCLIExe -i $ItemFullName -o ${ItemDirectoryName}\${ItemTitle}.mp4 --preset `"Fast 1080p30`" --subtitle-lang-list `"eng`" --subtitle-burned=`"none`" --subtitle-default=`"none`" --subname=`"English`"" -ForegroundColor Green
            & $HandBrakeCLIExe -i $ItemFullName -o ${ItemDirectoryName}\${ItemTitle}.mp4 --preset "Fast 1080p30" --subtitle-lang-list "eng" --subtitle-burned="none" --subtitle-default="none" --subname="English"
            if (-not (Test-Path -Path ${ItemDirectoryName}\${ItemTitle}.mp4)) {
                Write-Error "Failed to convert MKV to MP4. Exiting."
                return
            }
            Write-Host ""

            Write-Host "$(Get-Date -Format "HH:mm:ss"): Moving original MKV to Done: $ItemFullName" -ForegroundColor Green # TODO: Delete original MKV file instead.
            Move-Item -Path $ItemFullName -Destination $ItemDoneDirectory
            Write-Host ""

            Write-Host "$(Get-Date -Format "HH:mm:ss"): Start-BitsTransfer -Source ${ItemDirectoryName}\${ItemTitle}.mp4 -Destination $Destination -DisplayName 'Transfer video file' -Description 'Transfer Video File..'" -ForegroundColor Green
            Start-BitsTransfer -Source ${ItemDirectoryName}\${ItemTitle}.mp4 -Destination $Destination -DisplayName 'Transfer video file' -Description 'Transfer Video File..'

            Write-Host "$(Get-Date -Format "HH:mm:ss"): Moving converted MP4 to Done: ${ItemDirectoryName}\${ItemTitle}.mp4" -ForegroundColor Green
            Move-Item -Path ${ItemDirectoryName}\${ItemTitle}.mp4 -Destination $ItemDoneDirectory # TODO: Delete MP4 file instead.
            Write-Host ""

            if ($Loop) {
                Write-Host "$(Get-Date -Format "HH:mm:ss"): Start-Sleep -Seconds $SleepBetweenTasks (Next kick-off: $(Get-Date -Date (Get-Date).AddSeconds($SleepBetweenTasks) -Format "HH:mm:ss"))" -ForegroundColor Green
                Start-Sleep -Seconds $SleepBetweenTasks
                Write-Host ""
            }
        }
        else {
            if ($Loop) {
                Write-Debug "$(Get-Date -Format "HH:mm:ss"): No files found, sleeping for $SleepBetweenChecks seconds."
                Start-Sleep -Seconds $SleepBetweenChecks
            }
        }
    } while ($Loop)
}

function CreateDestinationFolderAsNecessary {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination
    )
    Write-Debug "$(Get-Date -Format "HH:mm:ss"): Destination: $Destination"

    if ([string]::IsNullOrWhiteSpace($Destination)) {
        Write-Error "Destination is null or empty."
        return
    }
    if (-not (Test-Path -Path $Destination)) {
        Write-Host "$(Get-Date -Format "HH:mm:ss"): Destination does not exist - Do you wish to create?- $Destination"
        $Choice = Read-Host "Y/N"
        if ($Choice -eq "Y") {
            Write-Host "$(Get-Date -Format "HH:mm:ss"): Creating folder: $Destination" -ForegroundColor Green
            New-Item -Path $Destination -ItemType Directory
        }
        return
    }
}