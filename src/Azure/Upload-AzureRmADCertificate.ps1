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

#region Functions
# Function to get Azure AD resource based on Application Id
Function Get-AzureAdResource ($ApplicationId)
{
	Write-Verbose "Searching for AAD resource using Application ID: $($ApplicationId)"
	$resource = Get-AzureRmADApplication -ApplicationId $ApplicationId

	If ($resource -eq $null)
	{
		throw [System.InvalidOperationException] "Application with AppId $($ApplicationId) does not exist"
	}
	
	Write-Verbose "AADResource.Name: $($resource.DisplayName)"
	Write-Verbose "AADResource.AppUri: $($resource.IdentifierUris)"
}

# Function to get certificate from path
Function Get-CertificateFromPath ($Path, $Password)
{
	Write-Verbose "Loading certificate from path: $($Path)"
	
	If (-not (Test-Path $Path)) 
	{
	    throw [System.IO.FileNotFoundException] "Certificate not found at path: $($Path)"
	}
	
	$certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 
	$certificate.Import($Path, $Password, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet) 
	Write-Verbose "Certificate.Thumbprint: $($certificate.Thumbprint)"
	
	$start = [datetime]::ParseExact([string]$certificate.GetEffectiveDateString(), 'dd-MM-yyyy HH:mm:ss', $null).ToUniversalTime()
	$end = [datetime]::ParseExact([string]$certificate.GetExpirationDateString(), 'dd-MM-yyyy HH:mm:ss', $null).ToUniversalTime()
	Write-Verbose "Certificate.StartDate (UTC): $($start)"
	Write-Verbose "Certificate.EndDate (UTC): $($end)"
	Return $certificate
}
#endregion

# Step 1: Get certificate from file system and retrieve Start Date, End Date and Thumbprint
$certificate = Get-CertificateFromPath $Path $Password
$binCert = $certificate.GetRawCertData() 
$credential = [System.Convert]::ToBase64String($binCert)
$start = [datetime]::ParseExact([string]$certificate.GetEffectiveDateString(), 'dd-MM-yyyy HH:mm:ss', $null).ToUniversalTime()
$end = [datetime]::ParseExact([string]$certificate.GetExpirationDateString(), 'dd-MM-yyyy HH:mm:ss', $null).ToUniversalTime()

# Step 2: Get Azure AD Resource based on Application ID
$resource = Get-AzureAdResource $ApplicationId

# Step 3: Validate if certificate is already present (based on End Date) and upload if it isn't already present
$creds = Get-AzureRmADAppCredential -ApplicationId $ApplicationId | Where-Object { $_.Type -eq 'AsymmetricX509Cert' } | Where-Object { $_.EndDate -eq $end.ToString() }
Write-Verbose "$($creds.Count) certificate found with matching End Date"

If ( $creds.Count -eq 0 ) 
{ 
    Write-Warning "Uploading certificate to Azure AD resource"
    New-AzureRmADAppCredential -ApplicationId $ApplicationId -CertValue $credential -StartDate $start -EndDate $end 
}
else 
{
    Write-Warning "Not adding certificate since it is already present"
}

# Step 4: Get all uploaded certificates in the Azure AD resource
$credentials = Get-AzureRmADAppCredential -ApplicationId $ApplicationId | Where-Object { $_.Type -eq 'AsymmetricX509Cert' }
Write-Verbose "Total Certificates present: $($credentials.Count)"
$credentials

