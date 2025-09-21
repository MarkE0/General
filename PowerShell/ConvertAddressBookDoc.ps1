# Read a text file with address book entries and convert to Excel or CSV
# Each entry will have a first line of "Surname, Firstname" or "Surename, HusbandName & WifeName"
# After that there may be one or more lines of address.
# After that there may be a phone number line starting with "Tel.". This line may also contain a mobile number starting with "Mob."
# Entries are usually separated by a blank line, but not always.

[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path
)

# Define paths
$TextFile   = $Path
$OutputFile = $TextFile -replace "\.txt$", ".xlsx"

# Read the text file, remove empty lines
$Lines = Get-Content $TextFile | Where-Object { $_.Trim() -ne "" }

# Container for parsed records
$Records = @()

# Walk through 3 lines at a time
# Parse entries based on the criteria
$AddressEntry = @()
foreach ($Line in $Lines) {
    if ($Line -match '\w, +\w' -or $Line -match 'END') {
        Write-Verbose "New Address: $Line"
        if ($AddressEntry.Count -gt 0) {
            # Process previous entry
            $Name    = $AddressEntry[0]
            $Address = ($AddressEntry[1..($AddressEntry.Count-1)] | Where-Object { $_ -notmatch '^(Tel|Mob)' }) -join ', '
            $Phone   = ""
            # Look for phone line
            foreach ($eLine in $AddressEntry) {
                Write-Verbose "  Examining line for phone: $eLine"
                if ($eLine -match '(^Tel|Tel\.|^Mob|Mob\.)') {
                    $Phone = $eLine.Trim()
                    Write-Verbose "    Found phone: $Phone"
                }
            }
            $Records += [PSCustomObject]@{
                Name    = $Name
                Address = $Address
                Phone   = $Phone
            }
        }

        if ($Line -match '^END$') {
            break
        }

        $AddressEntry = @($Line.Trim().TrimEnd(',') -replace '\s+', ' ')
    } else {
        Write-Verbose "    Adding line to entry: $Line"
        $AddressEntry += ($Line.Trim().TrimEnd(',') -replace '\s+', ' ')
    }
}

$Records | Export-Excel -Path $OutputFile -AutoSize -AutoFilter -Title "Address Book" -WorksheetName "Addresses" -Show

