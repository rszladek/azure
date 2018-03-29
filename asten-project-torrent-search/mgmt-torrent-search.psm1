<#
    .synopsis
    Module contains functions/cmdlets in order to perform some torrent researches on Torrent9 
    .description
    Module contains following functions:
        -Find-TorrentFile
        -Send-MessageTorrentAvailable
        -Get-TorrentFile
        -Send-TorrentFileToSA
    .notes
    Author: ASTEN FR
#>

function Find-TorrentFile {
<#
    .synopsis
    Search for torrent file
    .description
    Search for torrent file
    .notes
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]$Name,
        [Parameter(Mandatory=$true)]
        [Int16]$Season,
        [Parameter(Mandatory=$true)]
        [int16]$StartEpisode                
    )
    
    # Variables
    $url = "http://www.torrent9.red/get_torrent/"
    $extensionFile = ".torrent"
    $seasonNumber = "{0:D2}" -f $Season
    $endEpisode = 28
    $values = @()

    # Code Logic
    Write-Verbose -Message "[SEARCH] Torrent <$Name> - <S$seasonNumber> from episode <$StartEpisode>"

    try {
        for ($i = $StartEpisode; $i -lt $endEpisode; $i++) {
            # 2 digits format XX
            $episodeNumber = "{0:D2}" -f $i
            $requestUrl = $url + $Name + "-s" + $seasonNumber + "e" + $episodeNumber + "-vostfr-hdtv" + $extensionFile
            try {
                Write-Verbose " [CHECK] url <$requestUrl> ..."
                $request = Invoke-WebRequest -Uri $requestUrl
                $values += @{"Episode" = $episodeNumber; "URL" = $requestUrl; "Available" = $true; "ErrorMessage" = $null}
            }
            catch {
                # Stop exexution and send details
                $values += @{"Episode" = $episodeNumber; "URL" = $requestUrl; "Available" = $false; "ErrorMessage" = $_.Exception.Message}
                $i = $endEpisode
            }
            # wait before next request
            Start-Sleep -Seconds 5
        }

        # Return Result in JSON
        $result = @{"Name" = $Name; "Season" = $seasonNumber; "Result" = $values}
        Write-Output $result | ConvertTo-JSON
    }
    catch {
        # Send default exception
        Write-Error -Message $_.Exception.Message -ErrorAction Stop
    }
}