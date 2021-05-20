# Update-ScreenConnectLECert
This script automates the process of importing the Let's Encrypt SSL Certificate into Windows and binds it to ConnectWise Control.  This script does not handle the original issuance of the SSL certificate or the renewals, but this document will attempt to walk the user through the process.

## Prerequisites
The use of this script requires that Certbot is installed and used to obtain the initial SSL certificate on the ConnectWise Control server.  It also requires that openssl is installed and configured on the ConnectWise Control server.  This README file will attempt to walk the user through these prerequisites.

Additionally, public DNS record(s) must be valid for the domain(s) you desire to use for the certificate.  The firewalls (both network and server) must be configured to permit both port 80 and port 443 from the Internet to the ConnectWise Control server.  This README does not address how to modify public DNS or open and direct port 80 and 443 traffic to this server.  If you need assistance, please contact your local network and server support personnel.

## Certbot
Please reference the following documentation to set up and run Certbot to issue the initial certificate [https://certbot.eff.org/lets-encrypt/windows-other.html](https://certbot.eff.org/lets-encrypt/windows-other.html).  Since ConnectWise Control uses it's own web server, instructions for Apache, Nginx and IIS are not applicable.  Therefore instructions for 'None of the above on Windows' are required.

### Install Certbot
Download and install the Certbot installer [https://dl.eff.org/certbot-beta-installer-win32.exe](https://dl.eff.org/certbot-beta-installer-win32.exe).

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
