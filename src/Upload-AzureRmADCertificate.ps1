#########################################################################################################################
# Task         :	Upload Certificate to Azure AD resource
# Description  :	Upload a local certificate file (.cer or .pfx) to an Azure AD resource if it isn't already present. 
#					Validates whether the Azure AD resource already contains the same certificate based on the end date.
#
#					Ideally the certificate thumbprint would be the right approach for comparison but currently the 
#					Powershell cmdlet 'Get-AzureRmADAppCredential' doesn't have the ability to return the thumbprint. So 
#					the end date comparision is used as a workaround.
#
# Version      :	1.0.0
# Author       :	Degant Puri
# Input        :	-Path  
#						Local file system Path of certificate 
#					-ApplicationId
#						Application Id of Azure AD resource
#########################################################################################################################

param (
	[string] $Path,
	[string] $Password,
	[string] $ApplicationId
)

Write-Host '[verbose] Loading certificate from path:' $Path

If (-not (Test-Path $Path)) 
{
    throw [System.IO.FileNotFoundException] "Certificate not found"
}

$certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 
$certificate.Import($Path, $Password, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet) 
$binCert = $certificate.GetRawCertData() 
$credential = [System.Convert]::ToBase64String($binCert)

Write-Host '[verbose] Certificate.Thumbprint:' $certificate.Thumbprint

$start = [datetime]::ParseExact([string]$certificate.GetEffectiveDateString(), 'dd-MM-yyyy HH:mm:ss', $null).ToUniversalTime()
$end = [datetime]::ParseExact([string]$certificate.GetExpirationDateString(), 'dd-MM-yyyy HH:mm:ss', $null).ToUniversalTime()

Write-Host '[verbose] Certificate.StartDate (UTC):' $start
Write-Host '[verbose] Certificate.EndDate (UTC):' $end

Write-Host '[verbose] Searching for AAD resource using App ID: "'$ApplicationId'"'
$resource = Get-AzureRmADApplication -ApplicationId $ApplicationId
Write-Host "[verbose] AAD resource found: "$resource.DisplayName "-" $resource.IdentifierUris
$creds = Get-AzureRmADAppCredential -ApplicationId $ApplicationId | Where-Object { $_.Type -eq 'AsymmetricX509Cert' } | Where-Object { $_.EndDate -eq $end.ToString() }
Write-Host [verbose] $creds.Count certificate found with matching End Date

If ( $creds.Count -eq 0 ) 
{ 
    Write-Host [information] Upload certificate to Azure AD resource
    New-AzureRmADAppCredential -ApplicationId $ApplicationId -CertValue $credential -StartDate $start -EndDate $end 
}
else 
{
    Write-Host [warning] Not adding certificate since it is already present
}

$credentials = Get-AzureRmADAppCredential -ApplicationId $ApplicationId | Where-Object { $_.Type -eq 'AsymmetricX509Cert' }
Write-Host '[verbose] Total Certificates present: ' $credentials.Count
$credentials