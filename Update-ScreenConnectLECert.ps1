#  Update-ScreenConnectLECert.ps1
#
#  ScreenConnect / Let's Encrypt / Cerbot Script
#
#  This script takes a recently renewed Let's Encrypt SSL certificate renewed by Certbot
#  and applies it to the local Screen Connect server
#  
#  Created by Andy Boell, NNNC
#
#  Last Updated: 5/18/2021

function Logging {
    param([string]$Message)
    Write-Host $Message
    $Message >> $LogFile
}

# Define log file and make initial entry to indicate this script has run
$LogFile = 'c:\certs\SSLCert.log'
Logging -Message "Script start $(Get-Date)"

# Test if the certificate has been renewed
if((Get-ChildItem C:\Certbot\live\connect.esu1.org | ? LastWriteTime -gt (Get-Date).AddDays(-7) | Measure-Object).Count -gt 0)
{
    Logging -Message "Certificate renewed within the last 7 days"
    # Create PFX
    Logging -Message "Create PFX"
    $certPath = "c:\certs\connect-$(get-date -f yyyy-MM-dd).pfx"
    openssl pkcs12 -inkey C:\Certbot\live\connect.esu1.org\privkey.pem -in C:\Certbot\live\connect.esu1.org\cert.pem -certfile C:\Certbot\live\connect.esu1.org\fullchain.pem -export -out $certPath -password pass:connect

    # Delete existing SSL certificate bind to port 443
    Logging -Message "Delete existing SSL certificate bind to port 443"
    netsh http delete sslcert ipport=0.0.0.0:443

    # Remove old certs
    Logging -Message "Remove old cert from LocalMachine\My certificate store"
    ls Cert:\LocalMachine\My | ? Subject -eq "CN=connect.esu1.org"  | remove-item -Force

    # Import certificate into certificate store
    Logging -Message "Import new SSL certificate to LocalMachine\My certificate store"
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation Cert:\LocalMachine\My -Password ('connect' | ConvertTo-SecureString -AsPlainText -Force)

    # Get new cert
    Logging -Message "Query certificate store to get the new certificate"
    $cert = Get-ChildItem -Path Cert:\LocalMachine\My | ? Subject -eq "CN=connect.esu1.org"

    # Bind new SSL certificate to port 443
    Logging -Message "Bind new SSL certificate to port 443 for Screen Connect's use"
    netsh http add sslcert ipport=0.0.0.0:443 certhash=$($cert.Thumbprint) appid="{00000000-0000-0000-0000-000000000000}"
}
else
{
    Logging -Message "Certificate not renewed within the last 7 days"
}
Logging -Message "Script complete $(Get-Date)"
