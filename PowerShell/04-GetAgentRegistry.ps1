# Connect to Microsoft Graph, and run this request:
# GET https://graph.microsoft.com/beta/copilot/admin/catalog/packages
# See help at https://learn.microsoft.com/en-us/microsoft-365/copilot/extensibility/api/admin-settings/package/copilotpackages-list

# Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
Import-Module Microsoft.Graph.Authentication
# Install once (run as admin or with -Scope CurrentUser)
Import-Module -Name ImportExcel -Scope CurrentUser

# Read config
$config = Get-Content -Path ".\config.json" -Raw | ConvertFrom-Json
$tenantId = $config.tenantId
$clientId = $config.clientId

# Connect to Microsoft Graph with the required scope.
Connect-MgGraph -TenantId $tenantId -Scopes "CopilotPackages.Read.All"

# Call the API
$uri = "https://graph.microsoft.com/beta/copilot/admin/catalog/packages"
$response = Invoke-MgGraphRequest -Method GET -Uri $uri

# Normalize API response once so table/CSV/Excel stay in sync
$packages = $response.value | ForEach-Object {
    [PSCustomObject]@{
        Id                   = $_.id
        DisplayName          = $_.displayName
        Type                 = $_.type
        ShortDescription     = $_.shortDescription
        IsBlocked            = $_.isBlocked
        SupportedHosts       = ($_.supportedHosts -join ", ")
        LastModifiedDateTime = $_.lastModifiedDateTime
        Publisher            = $_.publisher
        AvailableTo          = $_.availableTo
        DeployedTo           = $_.deployedTo
        ElementTypes         = ($_.elementTypes -join ", ")
    }
}

# Output the packages
$packages | Format-Table -AutoSize

# Export CSV
$packages | Export-Csv ".\04-agentregistry.csv" -NoTypeInformation

# Export Excel (.xlsx) using ImportExcel module
$packages | Export-Excel -Path ".\04-agentregistry.xlsx" -WorksheetName "AgentRegistry" -TableName "AgentRegistry" -AutoSize -ClearSheet
