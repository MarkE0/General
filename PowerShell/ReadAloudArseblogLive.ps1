[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]
    $Url = "https://arseblog.live/liveblog/",

    [Parameter(Mandatory=$false)]
    [int]
    $CheckLoopSeconds = 1,

    [Parameter(Mandatory=$false)]
    [int]
    $UpdatesReadOutCount = 0,    # Start at 0 to read all

    [Parameter(Mandatory=$false)]
    [int]
    $ExitCountdown = 30
)

# ========== SET UP ==========
# Start the Firefox driver
$Driver = Start-SeFirefox #-Headless

# Apply the URL
Enter-SeUrl -Url $Url -Driver $Driver
# Enter-SeUrl -Url "https://arseblog.live/liveblog/67b05a163b249c0008f449d3" -Driver $Driver

# Add-Type -AssemblyName System.Speech
$Speech = New-Object System.Speech.Synthesis.SpeechSynthesizer
# $Speech.SelectVoice("Microsoft Zira Desktop")
# $Speech.Speak("This is a test.")

# Get the live updates element
$LiveBlogUpdateList = Get-SeElement -Selection "liveblogUpdateList" -By ClassName -Target $Driver

$ExitCountdownStarted = $false

while ($ExitCountdown -gt 0) {
    # Get the text of the live updates, merge lines as needed, and split it into an array
    $LiveBlogUpdatesArray = $LiveBlogUpdateList.Text `
        -replace '([^\r\n]+)[\r\n]+([^\r\n]+)[\r\n]+','$1 :: $2 xyz' `
        -split " xyz"
    # Write-Host "    DEBUG: ======================`n`t`t$($LiveBlogUpdatesArray | Select-Object -First 2 | Join-String -Separator "`n`t`t")`n           ======================"

    $LatestUpdatesCount = $LiveBlogUpdatesArray.Count
    # Write-Host "    DEBUG: UpdateCountMax($LatestUpdatesCount) -gt UpdateCounter($UpdatesReadOutCount)"
    if($LatestUpdatesCount -gt $UpdatesReadOutCount) {
        $ReadingUpdatesPosition = $LatestUpdatesCount - $UpdatesReadOutCount -1 # Subtract 1 to get the correct index since it starts at 0
        # Write-Host "    DEBUG: Update Count Position: $ReadingUpdatesPosition"
        for ($i = $ReadingUpdatesPosition; $i -ge 0; $i--) {
            $UpdateText = $LiveBlogUpdatesArray[$i]
            if ($UpdateText -ne "") {
                # Fix pronunciations
                $UpdatedSpoken = $UpdateText
                $UpdatedSpoken = $UpdatedSpoken -replace "Patreon","Paitreeon" -replace "\bFT\b","Full time" -replace "fk","Free kick" -replace 'Oo[o]+h',"Woah" -replace 'Go[oa]+al',"Goal"
                $UpdatedSpoken = $UpdatedSpoken -replace "Mikel","Mickel" -replace "Arteta","Artetuh" -replace "Arsenal","Arsnal"
                $UpdatedSpoken = $UpdatedSpoken -replace "Nwaneri","Nwan-airy" -replace "Gabriel","Gab-ri-ell" -replace "Raya","Rye-uh" -replace "Calafiori","Cal-afewer-ray" -replace "Jorginho","Jor-gene-yo" -replace "Saka","Sack-uh" -replace "Havertz","Hav-urtz"
                $UpdatedSpoken = $UpdatedSpoken -replace "Kiwior","Key-vee-or" -replace "Zinchenko","Zin-chenko" -replace "Saliba","Sahleeba"
                $UpdatedSpoken = $UpdatedSpoken -replace "\bOde\b", "Odegaard" -replace "\bMLS\b", "Lewis-Skelly" -replace "\bTross\b","Trossard" -replace "\bKT\b", "Kieran Tierney" -replace "Zinky","Zin-chenko"
   
                # Omit the time element if it matches the last one
                $TimeValue = ($UpdatedSpoken -split " :: ")[0]
                # Write-Host "    DEBUG: TimeValue: $TimeValue"
                if ($TimeValue -eq $PreviousTime) {
                    $UpdatedSpoken = $UpdatedSpoken -replace "$TimeValue :: ",""
                } elseif ($TimeValue -match '^\d+$') {
                    $UpdatedSpoken = $UpdatedSpoken -replace "$TimeValue :: ","$TimeValue minutes. "
                } elseif ($TimeValue -eq 'Half time' -or $TimeValue -eq 'Full time') {
                    $UpdatedSpoken = $UpdatedSpoken -replace "$TimeValue :: ",""
                } else {
                    $UpdatedSpoken = $UpdatedSpoken -replace "$TimeValue :: ","$TimeValue. "
                }

                $UpdateText = $UpdateText -replace " :: ", ". "
                if ($TimeValue -match '^\d+$') {
                    $UpdateText = $UpdateText -replace "$TimeValue. ", ""
                    $UpdateText = ("{0:D3}. {1}" -f [int]$TimeValue,$UpdateText)
                }

                $PreviousTime = $TimeValue
                if ($TimeValue -eq "Full time") {
                    $ExitCountdownStarted = $true
                    # Write-host "    DEBUG: Exit countdown started."
                }

                # Write-Host "[$(Get-Date -Format "HH:mm:ss"), (#:$LatestUpdatesCount)] $i --> $UpdateText"
                # Write-Host "[$(Get-Date -Format "HH:mm:ss"), (#:$("{0:D3}" -f $LatestUpdatesCount))] $("{0:D3}" -f $i) --> $UpdateText"
                Write-Host ("[$(Get-Date -Format "HH:mm:ss"), (#:{0:D3})] {1:D3}) --> $UpdateText" -f $LatestUpdatesCount,$i)
                # Write-Host "    DEBUG: $UpdatedSpoken"
                $Speech.Speak($UpdatedSpoken)
                start-sleep -seconds 1
            }
            $UpdatesReadOutCount++
        }
    }

    Start-Sleep -Seconds $CheckLoopSeconds
    if ($ExitCountdownStarted) {
        $ExitCountdown--
    }
}

# Stop
Write-Host "[$(Get-Date -Format "HH:mm:ss")] Stopping SeDriver..."
Stop-SeDriver -Driver $Driver

Write-Host "Exiting."
