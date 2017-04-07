# Powershell
Useful Powershell scripts

## 1. Upload Certificate to Azure Active Directory Resource
[Upload-AzureRmADCertificate.ps1](src/Upload-AzureRmADCertificate.ps1) - Upload a local certificate file (.cer or .pfx) to an Azure AD resource if it isn't already present. Validates whether the Azure AD resource already contains the same certificate based on the end date. 

Ideally the certificate thumbprint would be the right approach for comparison but currently the Powershell cmdlet 'Get-AzureRmADAppCredential' doesn't have the ability to return the thumbprint. So the end date comparision is used as a workaround.
