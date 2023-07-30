function Rename-VideoFileSeries {
    <#
    .SYNOPSIS
        Renames a set of video files to a common title, and moves them to a specified directory.
    .DESCRIPTION
        Renames a set of video files to a common title, and moves them to a specified directory.
        After a video file is extraced from a disk (using MakeMKV), it needs to be renamed to a
         common title and sequence number.
    .PARAMETER Path
        String. The path to the directory containing the video files.
    .PARAMETER TitleBase
        String. The base title to use for the video files. E.g. "Home Videos S04 E".
    .PARAMETER AdditionalLocation
        String. An additional directory where previously moved video files from the same series may be. E.g. a home server.
    .EXAMPLE
        > Rename-VideoFileSeries -Path "C:\Users\${env:USERNAME}\Videos\MakeMKV" -TitleBase "Home Videos S05 E" -AdditionalLocation "\\HomeServer\Videos\Home Videos\Series 5\"
        17:25:50: Checking for files matching Regex "[A-D][0-9]_t[0-9].*.mkv" in: C:\Users\User\Videos\MakeMKV
        17:25:50: Found item - Performing: Move-Item -Path "C:\Users\User\Videos\MakeMKV\C1_t02.mkv" -Destination "C:\Users\User\Videos\MakeMKV\Home Videos S05 E12.mkv"
    .EXAMPLE
        > Rename-VideoFileSeries -Path "C:\Users\${env:USERNAME}\Videos\MakeMKV" -TitleBase "Home Videos S05 E" -AdditionalLocation "\\HomeServer\Videos\Home Videos\Series 5\" -Loop
        17:26:06: Checking for files matching Regex "[A-D][0-9]_t[0-9].*.mkv" in: C:\Users\User\Videos\MakeMKV
        17:26:06: Found item - Performing: Move-Item -Path "C:\Users\User\Videos\MakeMKV\C1_t03.mkv" -Destination "C:\Users\User\Videos\MakeMKV\Home Videos S05 E13.mkv"
        17:26:11: Found item - Performing: Move-Item -Path "C:\Users\User\Videos\MakeMKV\C1_t04.mkv" -Destination "C:\Users\User\Videos\MakeMKV\Home Videos S05 E14.mkv"
        17:26:16: Found item - Performing: Move-Item -Path "C:\Users\User\Videos\MakeMKV\C1_t05.mkv" -Destination "C:\Users\User\Videos\MakeMKV\Home Videos S05 E15.mkv"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
    
        [Parameter(Mandatory=$true,Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$TitleBase,

        [Parameter(Mandatory=$false,Position=2)]
        [ValidateNotNullOrEmpty()]
        [string]$AdditionalLocation,

        [Parameter(Mandatory=$false)]
        [switch]$Loop
    )

    $RipTitleRegex     = "[A-D][0-9]_t[0-9].*.mkv" # E.g. "A1_t01.mkv"
    $SleepNoFilesFound = 30
    $SleepFilesFound   = 5
    $LastWriteSeconds  = -60

    Write-Host "$(Get-Date -Format "HH:mm:ss"): Checking for files matching Regex `"$RipTitleRegex`" in: $Path"

    do {
        Write-Debug "Start loop: $(Get-Date -Format "HH:mm:ss")"
        # Get the latest item that has been renamed as per the TitleBase format, or set a base name to start with.
        $LatestTitle = Get-ChildItem -Path $Path,$AdditionalLocation -Filter "${TitleBase}*.m*" | Sort-Object -Property BaseName | Select-Object -Last 1 | Select-Object -ExpandProperty BaseName
        Write-Debug "LatestTitle: `"$LatestTitle`""
        if ($null -eq $LatestTitle) {
            $LatestTitle = $TitleBase + "00"
            Write-Debug "LatestTitle not found, so initialising as: `"$LatestTitle`""
        }

        # Set a new title number in the format nn.
        $NewTitleNumber = [int]($LatestTitle -Replace "${TitleBase}","") + 1
        $NewTitle = "${TitleBase}{0:d2}" -f $NewTitleNumber
        Write-Debug "NewTitle: `"$NewTitle`""

        # Check for a new file, and rename it if it hasn't be written to for 60 seconds (e.g. it's finished).
        $EarliestNewFile = Get-ChildItem -Path $Path | Where-Object { $_.Name -match $RipTitleRegex } | Sort-Object -Property LastWriteTime | Select-Object -First 1

        if ($null -ne $EarliestNewFile) {
            $EarliestNewFileName = $EarliestNewFile.BaseName
            $EarliestNewFileFullName = $EarliestNewFile.FullName
            Write-Debug "EarliestNewFile (using Regex `"$RipTitleRegex`"): `"$EarliestNewFileName`""

            Write-Debug "Checking for last write time of ${EarliestNewFileName}: $($EarliestNewFile.LastWriteTime) -lt $((Get-Date).AddSeconds($LastWriteSeconds))"
            if (($EarliestNewFile).LastWriteTime -lt (Get-Date).AddSeconds($LastWriteSeconds)) {
                $EarliestNewFileNewFullName = $EarliestNewFileFullName -Replace "${EarliestNewFileName}","${NewTitle}"
                Write-Host "$(Get-Date -Format "HH:mm:ss"): Found item - Performing: Move-Item -Path `"$EarliestNewFileFullName`" -Destination `"$EarliestNewFileNewFullName`""
                Move-Item -Path "$EarliestNewFileFullName" -Destination "$EarliestNewFileNewFullName"
                
                if ($Loop) {
                    Start-Sleep -Seconds $SleepFilesFound
                }
                continue
            }
        }

        Write-Debug "No new file found, sleeping for $SleepNoFilesFound seconds.`n"
        if ($Loop) {
            Start-Sleep -Seconds $SleepNoFilesFound
        }
    } while ($Loop)
}
