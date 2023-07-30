Import-Module -Name BitsTransfer

function ConvertTo-MP4andTransferToServer {
    <#
    .SYNOPSIS
        Convert MKV to MP4 and transfer to server.
    .DESCRIPTION
        Convert MKV to MP4 and transfer to server.
        Requires HandBrake CLI to be installed.
          Reference: https://handbrake.fr/docs/en/1.6.0/cli/command-line-reference.html
        Progress bar on copy uses Bits Transfer module.
          Reference: https://stackoverflow.com/questions/2434133/progress-during-large-file-copy-copy-item-write-progress
    .PARAMETER Path
        String. The path to the MKV file to convert.
    .PARAMETER Destination
        String. The destination path to transfer the MP4 file to.
    .PARAMETER Loop
        Switch. Optional switch to continuously loop.
    .EXAMPLE
        > ConvertTo-MP4andTransferToServer -Path "C:\Users\${env:USERNAME}\Videos\MakeMKV\Home Videos S04*.mkv" -Destination "\\Server\Videoes\Home Videos\Series 4"
        19:25:11: TITLE: Home Videos S04 E11
        & C:\Program Files\HandBrake\HandBrakeCLI\HandBrakeCLI.exe -i C:\Users\User\Videos\MakeMKV\Home Videos S04 E11.mkv -o C:\Users\User\Videos\MakeMKV\Home Videos S04 E11.mp4 --preset "Fast 1080p30"
        . . .
        19:32:20: Moving original MKV to Done: C:\Users\User\Videos\MakeMKV\Home Videos S04 E11.mkv
        19:32:20: Start-BitsTransfer -Source C:\Users\User\Videos\MakeMKV\Home Videos S04 E11.mp4 -Destination \\Server\Videoes\Home Videos\Series 4 -DisplayName 'Transfer video file' -Description 'Transfer Video File..'
        19:33:05: Moving converted MP4 to Done: C:\Users\User\Videos\MakeMKV\Home Videos S04 E11.mp4
        19:33:05: Start-Sleep -Seconds 900 (Next kick-off: 19:48:05)
    .EXAMPLE
        > ConvertTo-MP4andTransferToServer -Path "C:\Users\${env:USERNAME}\Videos\MakeMKV\Wedding*.mkv" -Destination "\\Server\Home Movies"
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
        [switch]$Loop
    )
    
    $PostEncodeSleep = 900 # 15 minutes (let CPU cool down)
    $NonEncodeSleep  = 30  # 30 seconds
    $HandBrakeCliExe = "C:\Program Files\HandBrake\HandBrakeCLI\HandBrakeCLI.exe"

    # TODO: Check for files and folders.

    do {
        $Item = Get-Item -Path $Path | Sort-Object -Property LastWriteTime | Select-Object -First 1
        $ItemTitle = $Item.BaseName
        $ItemFullName = $Item.FullName
        $ItemDirectoryName = $Item.DirectoryName
        $ItemDoneDirectory = "${ItemDirectoryName}\Done"

        if ($null -ne $ItemTitle) {
            Write-Host "$(Get-Date -Format "HH:mm:ss"): TITLE: $ItemTitle" -ForegroundColor Green
            Write-Host "& $HandBrakeCLIExe -i $ItemFullName -o ${ItemDirectoryName}\${ItemTitle}.mp4 --preset `"Fast 1080p30`"" -ForegroundColor Green
            & $HandBrakeCLIExe -i $ItemFullName -o ${ItemDirectoryName}\${ItemTitle}.mp4 --preset "Fast 1080p30"
            Write-Host ""
            # TODO: Check convert success.

            Write-Host "$(Get-Date -Format "HH:mm:ss"): Moving original MKV to Done: $ItemFullName" -ForegroundColor Green
            Move-Item -Path $ItemFullName -Destination $ItemDoneDirectory
            Write-Host ""

            Write-Host "$(Get-Date -Format "HH:mm:ss"): Start-BitsTransfer -Source ${ItemDirectoryName}\${ItemTitle}.mp4 -Destination $Destination -DisplayName 'Transfer video file' -Description 'Transfer Video File..'" -ForegroundColor Green
            Start-BitsTransfer -Source ${ItemDirectoryName}\${ItemTitle}.mp4 -Destination $Destination -DisplayName 'Transfer video file' -Description 'Transfer Video File..'

            Write-Host "$(Get-Date -Format "HH:mm:ss"): Moving converted MP4 to Done: ${ItemDirectoryName}\${ItemTitle}.mp4" -ForegroundColor Green
            Move-Item -Path ${ItemDirectoryName}\${ItemTitle}.mp4 -Destination $ItemDoneDirectory
            # TODO: Delete original MKV file / Converted MP4 file if successful
            Write-Host ""

            if ($Loop) {
                Write-Host "$(Get-Date -Format "HH:mm:ss"): Start-Sleep -Seconds $PostEncodeSleep (Next kick-off: $(Get-Date -Date (Get-Date).AddSeconds($PostEncodeSleep) -Format "HH:mm:ss"))" -ForegroundColor Green
                Start-Sleep -Seconds $PostEncodeSleep
                Write-Host ""
            }
        }
        else {
            if ($Loop) {
                Write-Debug "$(Get-Date -Format "HH:mm:ss"): No files found, sleeping for $NonEncodeSleep seconds."
                Start-Sleep -Seconds $NonEncodeSleep
            }
        }
    } while ($Loop)
}
