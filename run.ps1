using namespace System.Net
# HTTP isteğini almak için 'param' tanımlaması
param($myTimer)


# Exchange bağlantı adresini ve e-posta kimlik bilgilerini ayarlayın
$ExchangeServer = $env:ExchangeServer    # Değiştirin: Exchange sunucunuzun FQDN veya IP adresi
$Email = $env:Email                      # Değiştirin: Test e-posta adresiniz
$Password = $env:Password                # Değiştirin: Test e-posta şifresi (Environment variable olarak kullanmak güvenlik için önerilir)
$AsyncUser = $env:AsyncUser
$connectionString = $env:BlobString
$containerName = "logs"
$notificationUrl = $env:NotificationUrl

function Test-ActiveSyncConnection {
    param (
        [string]$Server,
        [string]$Username,
        [string]$Password,
        [string]$Email,
        [string]$DeviceId,
        [string]$DeviceType = "SmartPhone"
    )

    $uri = "https://$Server/Microsoft-Server-ActiveSync?Cmd=FolderSync&User=$Email&DeviceId=$DeviceId&DeviceType=$DeviceType"
    write-host $uri
    
    # Temel kimlik doğrulama başlıklarını oluşturma
   
   
       $authString = $Username+":"+$Password
    $base64Auth = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($authString))



    $headers = @{
        "Authorization" = "Basic $base64Auth"
        "Content-Type" = "application/vnd.ms-sync.wbxml"
        "MS-ASProtocolVersion" = "14.1"  # ActiveSync sürümü, sunucuya göre ayarlanabilir
    }

    # Örnek WBXML veri yükü
    $wbxmlData = [System.Text.Encoding]::ASCII.GetBytes([char]0x03 + [char]0x01 + [char]0x6A + [char]0x00 + [char]0x6A + [char]0x05 + [char]0x00)

    try {
        $response = Invoke-WebRequest -Uri $uri -Method Post -Headers $headers -Body $wbxmlData -UseBasicParsing -ErrorAction Stop

        return $response.StatusCode
 
    } catch {
        Write-Host "Bir hata oluştu: $_"
        return $false
    }
}



# Çıkış JSON nesnesi
$output = @{
    DnsResolution = $null
    ConnectionTest = $null
    ActiveSyncTest = $null
    Timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
}

# 1. DNS Çözümleme
try {
    $dnsResult = [System.Net.Dns]::GetHostAddresses($ExchangeServer)
    $output.DnsResolution = @{
        Status = "Success"
    }
}
catch {
    $output.DnsResolution = @{
        Status = "Failure"
        ErrorMessage = $_.Exception.Message
    }
}

# 2. Exchange Bağlantı Testi (Exchange Web Services - EWS API kullanarak)
try {
    $ExchangeUri = "https://$ExchangeServer/EWS/Exchange.asmx"
    $securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($Email, $securePassword)

    $response = Invoke-WebRequest -Uri $ExchangeUri -Credential $credential -Method Get -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        $output.ConnectionTest = @{
            Status = "Success"
            HttpStatusCode = $response.StatusCode
            Message = "Connected to Exchange server successfully."
        }
    }
    else {
        $output.ConnectionTest = @{
            Status = "Failure"
            HttpStatusCode = $response.StatusCode
            Message = "Failed to connect to Exchange server."
        }
    }

    # 3. ActiveSync Bağlantı Testi
    try {
        
        $activeSyncResponse = Test-ActiveSyncConnection -Server $ExchangeServer -Username $AsyncUser -Password $Password  -Email $Email  -DeviceId "deneme1234"
        if ($activeSyncResponse -eq 200) {
            $output.ActiveSyncTest = @{
                Status = "Success"
                HttpStatusCode = 200
                Message = "ActiveSync connection successful."
            }
        }
        else {
            $output.ActiveSyncTest = @{
                Status = "Failure"
                HttpStatusCode = $activeSyncResponse
                Message = "ActiveSync connection failed."
            }
        }
    }
    catch {
        $output.ActiveSyncTest = @{
            Status = "Failure"
            ErrorMessage = $_.Exception.Message
        }
    }
}
catch {
    $output.ConnectionTest = @{
        Status = "Failure"
        ErrorMessage = $_.Exception.Message
    }
}


$outputJson = $output | ConvertTo-Json -Depth 3

# JSON'da en az bir 'Status' alanı 'Failure' ise veri gönder
if ($outputJson -match '"Status":\s*"Failure"') {
 
    $payload = @{
        text = "Azure Exchange kontrol testi.....  ews: "+ $output.ConnectionTest.Status +"- AS: "+$output.ActiveSyncTest.Status +" - DNS: " + $output.DnsResolution.Status
    } | ConvertTo-Json
    # curl komutu ile veri gönderme
    Invoke-RestMethod -Uri $notificationUrl -Method Post -Body $payload -ContentType "application/json"
}

# JSON çıktısını oluştur ve HTTP yanıtı olarak döndür
# HTTP tetikleyici ile çalıştırıldığında yanıt döndürme
if ($Request) {
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = 200
    Body = $outputJson
    Headers = @{ "Content-Type" = "application/json" }
})
}
