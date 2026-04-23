<#
.SYNOPSIS
    Pauses (suspends) a Microsoft Fabric capacity.

.DESCRIPTION
    This runbook authenticates using the Azure Automation managed identity
    and suspends the specified Fabric capacity. It is designed to run on a
    schedule to save costs during off-hours.

.PARAMETER SubscriptionId
    The Azure subscription ID that contains the Fabric capacity.

.PARAMETER ResourceGroupName
    The name of the resource group that contains the Fabric capacity.

.PARAMETER CapacityName
    The name of the Fabric capacity to pause.
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

# Suspend if currently active
if ($capacity.State -eq "Active") {
    try {
        Write-Output "Suspending Fabric capacity '$CapacityName'..."
        Suspend-AzFabricCapacity -ResourceGroupName $ResourceGroupName -CapacityName $CapacityName -DefaultProfile $AzureContext
        Write-Output "Fabric capacity '$CapacityName' has been suspended successfully."
    }
    catch {
        Write-Error "Failed to suspend Fabric capacity '$CapacityName': $_"
        throw
    }
}
elseif ($capacity.State -eq "Paused") {
    Write-Output "Fabric capacity '$CapacityName' is already paused. No action taken."
}
else {
    Write-Warning "Fabric capacity '$CapacityName' is in state '$($capacity.State)'. Skipping suspend."
}
