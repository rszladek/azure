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

function Set-AzureServiceBusSASToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]$ServiceBusResourceURI,
        [Parameter(Mandatory=$true)]
        [String]$AccessPolicyKeyName,
        [Parameter(Mandatory=$true)]
        [String]$AccessPolicyKey
    )

    # Set Token Expiration
    $sinceEpoch = (Get-Date).ToUniversalTime() - ([datetime]'1/1/1970')
    $weekInSeconds = 7 * 24 * 60 * 60
    $expiry = [System.Convert]::ToString([int]($sinceEpoch.TotalSeconds) + $weekInSeconds)

    # Set URI encoded
    $serviceBusResourceURIEncoded = [System.Web.HttpUtility]::UrlEncode($ServiceBusResourceURI)

    # Set signature encoding SHA256
    $stringToEncode = $serviceBusResourceURIEncoded + '`n' + $expiry
    $encodeStringBytes = [System.Text.Encoding]::UTF8.GetBytes($stringToEncode)
    $signatureString = New-Object -TypeName System.Security.Cryptography.HMACSHA256
    $signatureString.Key = [Text.Encoding]::UTF8.GetBytes($AccessPolicyKey)
    $signatureString = $signatureString.ComputeHash($encodeStringBytes)
    $signatureString = [System.Convert]::ToBase64String($signatureString)

    # Return result
    $sasToken = "SharedAccessSignature sig=$signatureString&se=$expiry&skn=$AccessPolicyKeyName&sr=$serviceBusResourceURIEncoded"
    return $sasToken

}

function Send-MessageTorrentAvailable {
<#
    .synopsis
    Send json data to Azure Service Bus
    .description
    Send json data to Azure Service Bus
    .notes
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]$Message,
        [Parameter(Mandatory=$true)]
        [String]$SasToken                 
    )

    # Variables
    $uri = "https://asten-torrent-search-dev-sb01.servicebus.windows.net/torrent-search-queue01"
    $sasToken = "iTh19SlhDt/rYLokqSMKRMxOcMLjN/CHt14I26hfF+c="
    $headers = @{'Authorization'=$SasToken} 
    $brokerProperties = @{
      State='Active'
      TimeToLive=10.0
    }
  
    # Set Header
    $brokerPropertiesJson = ConvertTo-Json $brokerProperties -Compress
    $headers.Add('BrokerProperties',$brokerPropertiesJson)

    # Set Message format
    $messageToPost = [System.Text.Encoding]::UTF8.GetBytes($Message)
    $contentType = 'application/atom+xml;type=entry;charset=utf-8'

    # API call
    try {
        Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $messageToPost -ContentType $contentType
        Write-Host "Rest API call success for $RestApiUri" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed To Send Message" -ForegroundColor Red
        Write-Error $_.Exception.Message
    }

}


$Namespace = "https://asten-torrent-search-dev-sb01.servicebus.windows.net/torrent-search-queue01"
$Key = "qjieUEtyQE6Z0XYpx+hOCJJ7B7EPMOLJy3KcIpkYjMw="
$PolicyName = "RootManageSharedAccessKey"

$endDate=[datetime]"4/1/2018 00:00"
$origin = [DateTime]"1/1/1970 00:00"
$diff = New-TimeSpan -Start $origin -End $endDate
$tokenExpirationTime = [Convert]::ToInt32($diff.TotalSeconds)

$stringToSign = [Web.HttpUtility]::UrlEncode($Namespace) + "`n" + $tokenExpirationTime

$hmacsha = New-Object -TypeName System.Security.Cryptography.HMACSHA256 
$hmacsha.Key = [Text.Encoding]::UTF8.GetBytes($Key)

$hash = $hmacsha.ComputeHash([Text.Encoding]::UTF8.GetBytes($stringToSign))
$signature = [Convert]::ToBase64String($hash)

$token3 = [string]::Format([Globalization.CultureInfo]::InvariantCulture, `
    "SharedAccessSignature sr={0}&sig={1}&se={2}&skn={3}", `
    [Web.HttpUtility]::UrlEncode($Namespace), `
    [Web.HttpUtility]::UrlEncode($signature), `
    $tokenExpirationTime, `
    $PolicyName)