# ===============================================================
# Azure VM Provisioning Tool (Cyber Range - Master Version) v.1.0
# ===============================================================

Clear-Host

# --- PERSISTENCE LOGIC: Saves RG after verified first run ---
$SavedRG = "" 

if ([string]::IsNullOrWhiteSpace($SavedRG)) {
    $ValidRGFound = $false
    while (-not $ValidRGFound) {
        Write-Host "===============================================" -ForegroundColor Cyan
        Write-Host "       INITIAL SETUP: RESOURCE GROUP" -ForegroundColor Cyan
        Write-Host "===============================================" -ForegroundColor Cyan
        $InputRG = (Read-Host "Enter your student resource group name. Starts with 'student-rg-' (copy/paste from portal)").Trim()
        
        Write-Host "Verifying access with Azure..." -ForegroundColor Gray
        $Exists = az group exists --name $InputRG
        
        if ($Exists -eq "true") {
            $ResourceGroup = $InputRG
            $ValidRGFound = $true
            $ScriptPath = $MyInvocation.MyCommand.Path
            if ($ScriptPath) {
                (Get-Content $ScriptPath) -replace '(\$SavedRG = )""', "`$SavedRG = `"$ResourceGroup`"" | Set-Content $ScriptPath
                Write-Host "[+] Verified! Resource Group saved for future runs.`n" -ForegroundColor Green
            }
        } else {
            Write-Host "[!] Resource Group not found. Check spelling and try again.`n" -ForegroundColor Red
        }
    }
} else {
    $ResourceGroup = $SavedRG
    Write-Host "[+] Using saved Resource Group: $ResourceGroup" -ForegroundColor Green
}

# --- 1. Sticky OS Selection Menu ---
$OSChoice = $null
do {
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host "      Azure VM Provisioning Tool (Cyber Range)" -ForegroundColor Cyan
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host "      1) Windows 11 (RDP enabled)"
    Write-Host "      2) Linux - Ubuntu Server 24.04 LTS (SSH enabled)"
    Write-Host "======================================================" -ForegroundColor Cyan
    $OSChoice = Read-Host "Enter choice (1 or 2)"
    switch ($OSChoice) {
        "1" { $OSType = "Windows"; $Image = "microsoftwindowsdesktop:windows-11:win11-25h2-pro:latest"; $Port = "3389"; $Valid = $true }
        "2" { $OSType = "Linux"; $Image = "Canonical:ubuntu-24_04-lts:server:latest"; $Port = "22"; $Valid = $true }
        default { 
        Clear-Host
        Write-Host "[!] Invalid selection.`n" -ForegroundColor Red; $Valid = $false }
    }
} until ($Valid)

# --- 2. User Input ---
Write-Host "`n[ Credentials ]" -ForegroundColor Yellow
$AdminUser     = (Read-Host "Enter admin username").Trim()
$AdminPassword = (Read-Host "Enter admin password")
$VMName        = (Read-Host "Enter name for NEW VM").Trim()

# --- 3. Environmental Constants ---
$LabSubID  = "3c95e63a-895a-4386-991e-edbbf57de5c8"
$SubnetID  = "/subscriptions/$LabSubID/resourceGroups/Cyber-Range-Admin/providers/Microsoft.Network/virtualNetworks/Cyber-Range-VNet/subnets/Cyber-Range-Subnet"
$Location  = "eastus2"

az account set --subscription $LabSubID | Out-Null

# --- 4. Quota Enforcement ---
$ExistingVMs = az vm list -g $ResourceGroup --query "[].name" -o tsv
if ($ExistingVMs) {
    Write-Host "`n[!] FOUND EXISTING VM: $ExistingVMs" -ForegroundColor Red
    $Confirm = Read-Host "Delete to stay within 1-VM quota? (Y/N)"
    if ($Confirm -eq "Y" -or $Confirm -eq "y") {
        foreach ($vm in $ExistingVMs) {
            Write-Host "[!] Purging $vm and resources..." -ForegroundColor Red
            az vm delete -g $ResourceGroup -n $vm --yes --no-wait
            $res = az resource list -g $ResourceGroup --query "[?contains(name, '$vm')].id" -o tsv
            if ($res) { az resource delete --ids $res --verbose }
        }
    } else { Write-Host "Exiting."; exit }
}

# --- 5. Deployment ---
Write-Host "`n[!] Deploying $OSType VM with Standard SSD..." -ForegroundColor Cyan
az vm create `
  --resource-group $ResourceGroup `
  --name $VMName `
  --location $Location `
  --image $Image `
  --size Standard_DS1_v2 `
  --admin-username $AdminUser `
  --admin-password $AdminPassword `
  --subnet $SubnetID `
  --storage-sku StandardSSD_LRS `
  --public-ip-sku Standard `
  --nsg-rule NONE `
  --os-disk-delete-option Delete

# --- 6. Port Opening & Reporting ---
if ($LASTEXITCODE -eq 0) {
    Write-Host "[!] Opening port $Port..." -ForegroundColor Yellow
    az vm open-port --resource-group $ResourceGroup --name $VMName --port $Port --priority 100 > $null
    $IP = az vm list-ip-addresses -g $ResourceGroup -n $VMName --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv
    Write-Host "`n===============================================" -ForegroundColor Green
    Write-Host " SUCCESS: VM Deployed & Port $Port Opened!"
    Write-Host " SUCCESS: Remote session NSG Rule Created"
    Write-Host "-----------------------------------------------"
    Write-Host " VM Name   : $VMName"
    Write-Host " Public IP : $IP"
    Write-Host " Connect   : Use $($OSType -eq 'Windows' ? 'RDP' : 'SSH') to $IP"
    Write-Host "==============================================="
}
