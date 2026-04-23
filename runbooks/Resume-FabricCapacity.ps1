<#
.SYNOPSIS
    Resumes (starts) a Microsoft Fabric capacity.

.DESCRIPTION
    This runbook authenticates using the Azure Automation managed identity
    and resumes the specified Fabric capacity. It is designed to run on a
    schedule to bring the capacity back online during business hours.

.PARAMETER SubscriptionId
    The Azure subscription ID that contains the Fabric capacity.

.PARAMETER ResourceGroupName
    The name of the resource group that contains the Fabric capacity.

.PARAMETER CapacityName
    The name of the Fabric capacity to resume.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$CapacityName
)

# Do not inherit an AzContext from a previous runbook
Disable-AzContextAutosave -Scope Process | Out-Null

# Authenticate with the system-assigned managed identity
try {
    $AzureContext = (Connect-AzAccount -Identity).Context
    $AzureContext = Set-AzContext -SubscriptionId $SubscriptionId -DefaultProfile $AzureContext
    Write-Output "Successfully authenticated with managed identity."
}
catch {
    Write-Error "Failed to authenticate with managed identity: $_"
    throw
}

# Check current capacity state
try {
    $capacity = Get-AzFabricCapacity -ResourceGroupName $ResourceGroupName -CapacityName $CapacityName -DefaultProfile $AzureContext
    Write-Output "Capacity '$CapacityName' current state: $($capacity.State)"
}
catch {
    Write-Error "Failed to retrieve Fabric capacity '$CapacityName': $_"
    throw
}

# Resume if currently paused
if ($capacity.State -eq "Paused") {
    try {
        Write-Output "Resuming Fabric capacity '$CapacityName'..."
        Resume-AzFabricCapacity -ResourceGroupName $ResourceGroupName -CapacityName $CapacityName -DefaultProfile $AzureContext
        Write-Output "Fabric capacity '$CapacityName' has been resumed successfully."
    }
    catch {
        Write-Error "Failed to resume Fabric capacity '$CapacityName': $_"
        throw
    }
}
elseif ($capacity.State -eq "Active") {
    Write-Output "Fabric capacity '$CapacityName' is already active. No action taken."
}
else {
    Write-Warning "Fabric capacity '$CapacityName' is in state '$($capacity.State)'. Skipping resume."
}
