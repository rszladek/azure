<#
    .Synospsis
    Download torrent files from torrent9

    .Author 
    Asten
#>


function getTorrentFiles () {

    param(
        [Parameter(Mandatory=$true)]
        [Array]$TvShow
    )

    # VARIABLES
    $maxEpisode = 30
    $destination = "C:\Users\Romain\Downloads\"
    $url = "http://www.torrent9.red/get_torrent/"
    $extensionFile = ".torrent"

    # BEGIN WITH SPECIFIC EPISODE
    $startSearch = 1
    if ($TvShow.EpisodeStart) {
        $startSearch = $TvShow.EpisodeStart
    }

    # SEARCH FILES
    Write-Host "[START] Searching on <$url> ..." -ForegroundColor Green
    foreach ($show in $tvShow) {
        Write-Host "    [$($show.Name)]"
        for ($i = $startSearch; $i -lt $maxEpisode; $i++) {
            $episodeNumber = "{0:D2}" -f $i
            $requestUrl = $url + $show.Name + "-s" + $show.Season + "e" + $episodeNumber + "-vostfr-hdtv" + $extensionFile
            $fileName = $show.Name + "-s" + $show.Season + "e" + $episodeNumber + "-vostfr-hdtv" + $extensionFile
            Start-Sleep -Seconds 5
            Write-Host "        [GET] Torrent File <$requestUrl> ..." -ForegroundColor DarkYellow
            try {
                $finalDestination = $destination + $fileName
                Invoke-WebRequest -Uri $requestUrl -OutFile $finalDestination
            }
            catch {
                Write-Host "        [404] Episode number max reach <$episodeNumber> `r`n $($_.Exception.Message)" -ForegroundColor Red
                # Stop loop
                $i = $maxEpisode
            }
        }
    }

    # END
    Write-Host "[END] Searching has been completed" -ForegroundColor Green
}

function setTorrentFile() {
    
    param(
        [Parameter(Mandatory=$true)]
        [String]$StringToRemove,
        [Parameter(Mandatory=$true)]
        [String]$Directory
    )

    # GET ITEMS INSIDE Directory
    Write-Host "[SEARCH] inside <$Directory> ..."
    $files = Get-ChildItem -Path $Directory -Recurse -Include "*.avi"
    # CLEAN names
    foreach ($file in $files) {
        Start-Sleep -Seconds 1
        Write-Host "    [GET] Name <$($file.Name)>" -ForegroundColor Green
        # Renaming
        if(($file.Name).Contains($StringToRemove)){
            Write-Host "        [RENAME] file <$($file.Name)>"
            $newName = $($file.Name).Replace($StringToRemove, "")
            Rename-Item -LiteralPath $file.FullName -NewName $newName
        }
        # Moving file
        if($Directory -ne $file.DirectoryName){
            Write-Host "        [MOVE] file <$($file.FullName)> to root directory" -ForegroundColor Cyan
            Move-Item -LiteralPath $file.FullName -Destination $Directory
        }
    }

}


####################### EXECUTION PART #########################################
$tvShow = @(
    @{"Name" = "dc-s-legends-of-tomorrow"; "Season" = "02"; "EpisodeStart"= 9}
)

getTorrentFiles -tvShow $TvShow

#setTorrentFile -StringToRemove "[ Torrent9.tv ] " -Directory  "D:\Mes documents\TOR"


