###############################################################################
# Task         : Upload Certificate to Azure AD resource
# Description  : Upload a local certificate file (.cer or .pfx) to an Azure AD
#                resource. Checks whether the Azure AD resource already contains
#				 a certificate with the same end date and doesn't upload if that
#				 is true. The End Date is used as a comparision mechanism because
#				 currently the Powershell cmdlet doesn't have the capability to 
#				 return the thumbprint, which would be a better solution.
# Version      : 1.0.0
# Author       : Degant Puri
# Input        : -Path  
#                    Local file system Path of certificate 
#                -ApplicationId
#                    Application Id of Azure AD resource
###############################################################################

param (
	[string] $Path,
    [string] $Password,
	[string] $ApplicationId
)

Write-Host '[verbose] Loading certificate from path "'$Path'"'
$cer = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 
$cer.Import($Path, $Password, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet) 
$binCert = $cer.GetRawCertData() 
$credValue = [System.Convert]::ToBase64String($binCert)

$binCert = $cer.GetCertHash()
$base64Thumbprint = [System.Convert]::ToBase64String($binCert)
Write-Host '[verbose] Thumbprint of certificate: '$cer.Thumbprint

$start = [datetime]::ParseExact([string]$cer.GetEffectiveDateString(), 'dd-MM-yyyy HH:mm:ss', $null)
$end = [datetime]::ParseExact([string]$cer.GetExpirationDateString(), 'dd-MM-yyyy HH:mm:ss', $null)
$start = $start.ToUniversalTime()
$end = $end.ToUniversalTime()
Write-Host '[verbose] Start Date of Certificate in UTC:' $start
Write-Host '[verbose] End Date of Certificate in UTC:' $end

Write-Host '[verbose] Searching for AAD resource using App ID: "'$ApplicationId'"'
$resource = Get-AzureRmADApplication -ApplicationId $ApplicationId
Write-Host "[verbose] AAD resource found: "$resource.DisplayName "-" $resource.IdentifierUris
$creds = Get-AzureRmADAppCredential -ApplicationId $ApplicationId | Where-Object { $_.Type -eq 'AsymmetricX509Cert' } | Where-Object { $_.EndDate -eq $end.ToString() }
Write-Host [verbose] $creds.Count certificate found with matching End Date

If ( $creds.Count -eq 0 ) 
{ 
    Write-Host [information] Upload certificate to Azure AD resource
    New-AzureRmADAppCredential -ApplicationId $ApplicationId -CertValue $credValue -StartDate $start -EndDate $end 
}
else 
{
    Write-Host [warning] Not adding certificate since it is already present
}

$credentials = Get-AzureRmADAppCredential -ApplicationId $ApplicationId | Where-Object { $_.Type -eq 'AsymmetricX509Cert' }
Write-Host '[verbose] Total Certificates present: ' $credentials.Count
$credentials

