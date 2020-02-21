[CmdletBinding()]
param (
    # Number of users to create
    [Parameter(Mandatory)]
    [int]
    $NumberOfAccounts,

    # Account Identifier Code
    [Parameter(Mandatory)]
    [string]
    $AccountIdentifierCode,

    # Account Description
    [Parameter()]
    [string]
    $AccountDescription,

    # Parameter help description
    [Parameter(Mandatory)]
    [securestring]
    $TestAccountPassword,

    # Credential
    [Parameter(Mandatory)]
    [pscredential]
    $Credential = (Get-Credential -Message "Enter Admin Credentials")
)
$ErrorActionPreference = "Stop"

$date = Get-Date

try {
    $allExistingAccounts = Get-ADUser -Filter "*" | select samaccountname
}
catch {
    Write-Error "Unable to collect existing users from AD"
}


$testAccounts = @()
$a = 0
do {
    $a++
    Write-Host "Test "+$AccountIdentifierCode+"User"+$a

    $surname = $AccountIdentifierCode+"User"+$a
    $testAccounts += [PSCustomObject]@{
        givenName      = "Test"
        surename       = $surname
        samAccountName = "T-"+$surname
    }

} until ($a -eq $NumberOfAccounts)

$description = "$AccountDescription. Created by $env:USERNAME on $Date with Purpose Code $AccountIdentifierCode."

foreach ($testUser in $testAccounts) {
    if ( $testUser.samaccountname -notin $allExistingAccounts ) {
        $newUser = @{
            Name           = $testUser.givenName+" "+$testUser.surename
            GivenName      = $testUser.givenName
            Surname        = $testUser.surename
            SamAccountName = $testUser.samAccountName
            Description = $description
            Credential = $Credential
        }
        
        New-ADUser @newUser
    }
    else {
        Write-Host $testUser.samaccountname+" already exists in AD. This account will not be created!" -ForegroundColor Yellow
    }
}

# Set Account password and enable accounts for use
foreach ($user in $testUser) {
    Set-ADAccountPassword -Identity $user.samAccountName -NewPassword $TestAccountPassword -Credential $Credential
    Enable-ADAccount $user.samAccountName -Credential $Credential
}

Write-Host "`n`nThe following account have been created with a description of:`n$description" -ForegroundColor Green
$testAccounts | Format-Table
Write-Host "`nAlert SOC of test accounts creationed" -ForegroundColor Yellow