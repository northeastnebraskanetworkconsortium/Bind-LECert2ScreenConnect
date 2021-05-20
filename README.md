# Bind-LECert2ScreenConnect
This script automates the process of importing the Let's Encrypt SSL Certificate into Windows and binds it to ConnectWise Control.  This script does not handle the original issuance of the SSL certificate or the renewals, but this document will attempt to walk the user through the process.

## Prerequisites
The use of this script requires that Certbot is installed and used to obtain the initial SSL certificate on the ConnectWise Control server.  It also requires that openssl is installed and configured on the ConnectWise Control server.  This README file will attempt to walk the user through these prerequisites.

Additionally, public DNS record(s) must be valid for the domain(s) you desire to use for the certificate.  The firewalls (both network and server) must be configured to permit both port 80 and port 443 from the Internet to the ConnectWise Control server.  This README does not address how to modify public DNS or open and direct port 80 and 443 traffic to this server.  If you need assistance, please contact your local network and server support personnel.

## Certbot
Please reference the following documentation to set up and run Certbot to issue the initial certificate [https://certbot.eff.org/lets-encrypt/windows-other.html](https://certbot.eff.org/lets-encrypt/windows-other.html).  Since ConnectWise Control uses it's own web server, instructions for Apache, Nginx and IIS are not applicable.  Therefore instructions for 'None of the above on Windows' are required.

### Install Certbot
Download and install the Certbot installer [https://dl.eff.org/certbot-beta-installer-win32.exe](https://dl.eff.org/certbot-beta-installer-win32.exe) on the ConnectWise Control server.

This installer automatically sets up and configures a scheduled task.  The Certbot installation files are in the C:\Program Files (x86)\Certbot directory and the certificates will be located in the C:\Cerbot directory. 

### Get initial certificate
As indicated in the instructions, you will need to open either a command shell or Powershell as administrator following the installation.  If you have an existing Powershell or command shell open prior to the Certbot installation you will need to open a new window to have access to the Cerbot additions to the environment variable that was added during installation.  To make sure you have appropriate permissions, issue the command:
```powershell
certbot --help
```
You should receive a verbose help listing with this command.

The following command can be used to request the initial certificate:
```powershell
certbot certonly --standalone --agree-tos -m email@domain.com -d connect.domain.com
```
Variations of this command:
- `-m email@domain.com` is for the email address that will be notified regarding communication about your certificate.  This includes expiration notices (in the event the auto renewal fails) or other administrative notices.
- `-d connect.domain.com` is the domain the certificate will be for.  If desired to include multiple domains, add multiple `-d connect.newdomain.com` to the command.  

Upon first running this command you may be prompted to opt in to share your email address with the Electronic Frontier Foundation.  This is optional, but does require interaction before the certificate request can be issued.

Successful certificate issuance will result in an output similar to
```
Saving debug log to C:\Certbot\log\letsencrypt.log
Plugins selected: Authenticator standalone, Installer None
Requesting a certificate for connect.domain.com
Performing the following challenges:
http-01 challenge for connect.domain.com
Waiting for verification...
Cleaning up challenges
Subscribe to the EFF mailing list (email: email@domain.com).
←[1m
IMPORTANT NOTES:
←[0m - Congratulations! Your certificate and chain have been saved at:
   C:\Certbot\live\connect.domain.com\fullchain.pem
   Your key file has been saved at:
   C:\Certbot\live\connect.domain.com\privkey.pem
   Your certificate will expire on 2021-08-18. To obtain a new or
   tweaked version of this certificate in the future, simply run
   certbot again. To non-interactively renew *all* of your
   certificates, run "certbot renew"
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le
```
Once the certificate is issued, as noted in the output provided, you can locate your certificate at `C:\Certbot\live\connect.domain.com\`

## openssl
openssl is used to take the .pem files provided by Certbot and convert them to a PFX so the script can import them into Windows and then ConnectWise Control.  If openssl is not already installed on the ConnectWise Control server, follow the instructions below.

### Install openssl
I followed instructions at [https://adamtheautomator.com/openssl-windows-10/](https://adamtheautomator.com/openssl-windows-10/), which does require Chocolatey to be installed on the server first.  If Chocolatey is not already installed on the ConnectWise Control server, it can be installed by following the official Chocolatey documentation, found [https://chocolatey.org/install](https://chocolatey.org/install).  In short, you can issue the following command to install Chocolatey 
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```

Please note that Chocolatey is not required to install openssl; it's just the method I used and I am referencing here.  As long as openssl is installed, Chocolatey is not necessary.

### Configure openssl
As outlined on the [https://adamtheautomator.com/openssl-windows-10/](https://adamtheautomator.com/openssl-windows-10/) instructions, openssl requires the `openssl.cnf` file to exist and configured.  Per these instructions, the `C:\certs` directory is created to contain the `openssl.cnf` file.  This directory is also referenced in the script as the location to capture and store the PFX file.  Once the `openssl.cnf` file is created and the Powershell profile is updated the remainder of the instructions are not necessary for this task (although if openssl is to be used for other reasons, it is recommended to follow the rest of the document).
