# Powershell
Useful Powershell scripts

## Azure
Collection of useful Azure Powershell scripts

### 1. Upload Certificate to Azure Active Directory Resource
[Upload-AzureRmADCertificate.ps1](src/Upload-AzureRmADCertificate.ps1) - Upload a local certificate file (.pfx) to an Azure AD resource if it isn't already present. Validates whether the Azure AD resource already contains the same certificate based on the end date. 

Ideally the certificate thumbprint would be the right approach for comparison but currently the Powershell cmdlet 'Get-AzureRmADAppCredential' doesn't have the ability to return the thumbprint. So the end date comparision is used as a workaround.

#### Input
* **$Path** - Location of certificate (.pfx)
* **$Password** - Password of certificate
* **$ApplicationId** - Application Id of the Azure AD resource

#### Usage
```powershell
Upload-AzureRmADCertificate.ps1 -Path "E:\custom-certificate.pfx" -ApplicationId "00001111-2222-3333-4444-555566667777" -Password 'certificatepassword'
```
