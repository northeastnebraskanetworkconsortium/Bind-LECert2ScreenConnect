#  Update-ScreenConnectLECert.ps1
#
#  ScreenConnect / Let's Encrypt / Cerbot Script
#
#  This script takes a Let's Encrypt SSL certificate by Certbot
#  and applies it to the local Screen Connect server
#  
#  Prerequisites:
#    - Certbot is installed and the certificate has been issued
#    - openssl is installed and configured properly
#
#  Created by Andy Boell, NNNC
#   aboell@esu2.org
#
#  Last Updated: 5/19/2021

function Logging {
    param([string]$Message)
    Write-Host $Message
    $Message >> $LogFile
}

# Define log file and make initial entry to indicate this script has run
$LogFile = 'c:\certs\SSLCert.log'
Logging -Message "Script start $(Get-Date)"
        
# Prerequisites check
try{
    if((Test-Path -Path C:\Certbot\live) -and (openssl version))
    {
        # Get Cerbot certificate folder 
        $certDirectoryName = Get-ChildItem -Directory -Path C:\Certbot\live

        # Test if the certificate has been renewed
        if((Get-ChildItem $certDirectoryName.FullName | ? LastWriteTime -gt (Get-Date).AddDays(-7) | Measure-Object).Count -gt 0)
        {
            Logging -Message "Certificate renewed within the last 7 days.  Needs to be imported into certificate store and bound to Screen Connect"
            # Create PFX
            Logging -Message "Set variables for openssl command"
            $certPath = "c:\certs\connect-$(get-date -f yyyy-MM-dd).pfx"
            $privkey = $certDirectoryName.FullName + '\privkey.pem'
            $cert = $certDirectoryName.FullName + '\cert.pem'
            $certfile = $certDirectoryName.FullName + '\fullchain.pem'
            try{
                Logging -Message "Create PFX"
                openssl pkcs12 -inkey $privkey -in $cert -certfile $certfile -export -out $certPath -password pass:connect
                Logging -Message "PFX successfully created: $($certPath)"
            }
            catch{
                Logging -Message "Error attempting to create PFX: $($certPath)"
                exit
            }

            # Import certificate into certificate store
            try{
                Logging -Message "Import new SSL certificate to LocalMachine\My certificate store"
                $importedCert = Import-PfxCertificate -FilePath $certPath -CertStoreLocation Cert:\LocalMachine\My -Password ('connect' | ConvertTo-SecureString -AsPlainText -Force)
            }
            catch{
                Logging -Message "Error with SSL certificate import"
                exit
            }

            # Delete existing SSL certificate bind to port 443
            Logging -Message "Delete existing SSL certificate bind to port 443"
            netsh http delete sslcert ipport=0.0.0.0:443

            # Bind new SSL certificate to port 443
            try{
                Logging -Message "Bind new SSL certificate to port 443 for Screen Connect's use"
                if(netsh http add sslcert ipport=0.0.0.0:443 certhash=$($importedCert.Thumbprint) appid="{00000000-0000-0000-0000-000000000000}" | Where-Object {$_ -match "successfully"}
                {
                    Logging -Message "Bind new SSL certificate successful"
                }
                else
                {
                    Logging -Message "Bind failed"
                }
            }
            catch{
                Logging -Message "Error occurred during SSL certificate bind."
                exit
            }

            # Remove old certs
            Logging -Message "Remove old cert from LocalMachine\My certificate store"
            # Count number of certificates before the remove command
            $beforeCount = (ls Cert:\LocalMachine\My).count
            ls Cert:\LocalMachine\My | ? Subject -eq "CN=$($certDirectoryName.Name)" | ? NotAfter -lt $(get-date) | remove-item -Force
            $afterCount = (ls Cert:\LocalMachine\My).count
            Logging -Message "$($beforeCount-$afterCount) certificates removed" 
        }
        else
        {
            Logging -Message "Certificate not renewed within the last 7 days"
        }
        Logging -Message "Script complete $(Get-Date)`n"
    }
    else
    {
        Logging -Message "Default path for Certbot installation not found.  Script terminated."
    }
}
catch
{
    Logging -Message "openssl not installed.  Script terminated."
}
