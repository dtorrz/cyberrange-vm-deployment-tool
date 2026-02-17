# ===============================================================
# Azure VM Provisioning Tool (Cyber Range - Master Version) v.2.0
# ===============================================================

Clear-Host
$StartTime = Get-Date

# --- 0. PRE-FLIGHT CHECK ---
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "[!] Azure CLI not found! Please install it from: https://aka.ms/installazurecliwindows" -ForegroundColor Red
    pause; exit
}


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
    $OSChoice = Read-Host "Which OS to install. Enter choice (1 or 2)"
    switch ($OSChoice) {
        "1" { $OSType = "Windows"; $Image = "microsoftwindowsdesktop:windows-11:win11-25h2-pro:latest"; $Port = "3389"; $Valid = $true }
        "2" { $OSType = "Linux"; $Image = "Canonical:ubuntu-24_04-lts:server:latest"; $Port = "22"; $Valid = $true }
        default { 
        Clear-Host
        Write-Host "[+] Using saved Resource Group: $ResourceGroup`n" -ForegroundColor Green

        Write-Host "[!] Invalid selection. Try again`n" -ForegroundColor Red; $Valid = $false }
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
    $Confirm = Read-Host "Would you like to delete to stay within 1-VM quota? (Y/N)"
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
    # Check OS type right here so it doesn't interfere with exit codes
    if ($OSType -eq "Windows") { $Method = "RDP" } else { $Method = "SSH" }

    Write-Host "[!] Opening port $Port..." -ForegroundColor Yellow
    az vm open-port --resource-group $ResourceGroup --name $VMName --port $Port --priority 100 > $null
    $Elapsed = (Get-Date) - $StartTime
    $IP = az vm list-ip-addresses -g $ResourceGroup -n $VMName --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv
    
    Write-Host "`n===============================================" -ForegroundColor Green
    Write-Host " SUCCESS: VM Deployed & Port $Port Opened!"
    Write-Host " Build Time: $($Elapsed.Minutes)m $($Elapsed.Seconds)s"
    Write-Host " Remote session NSG Rule Created"
    Write-Host "-----------------------------------------------"
    Write-Host " VM Name   : $VMName"
    Write-Host " Public IP : $IP"
    Write-Host " Username  : $AdminUser"
    Write-Host " Connect   : Use $Method to $IP"
    Write-Host "===============================================" -ForegroundColor Green
    


# --- 7. SMART AUTO-LAUNCH LOGIC (Windows & Linux) ---
    Write-Host "`n[!] Waiting for $OSType to initialize $Method services..." -ForegroundColor Yellow
    Write-Host "    (This may take a minute. Press Ctrl+C to skip waiting.)" -ForegroundColor Gray
    
    $IsReady = $false
    $Timeout = 30 # Try for 5 minutes total (30 checks * 10 seconds)
    $Counter = 0

    while (-not $IsReady -and $Counter -lt $Timeout) {
        # Test-NetConnection checks if the specific port (22 or 3389) is open
        $Check = Test-NetConnection -ComputerName $IP -Port $Port -WarningAction SilentlyContinue -InformationLevel Quiet
        
        if ($Check) {
            $IsReady = $true
        } else {
            Write-Host "." -NoNewline -ForegroundColor Cyan
            Start-Sleep -Seconds 5
            $Counter++
        }
    }

    if ($IsReady) {
        Write-Host "`n[+] VM is responding! $OSType is ready for connection." -ForegroundColor Green
        
        if ($Method -eq "RDP") {
            $Launch = Read-Host "Would you like to launch Remote Desktop now? (Y/N)"
            if ($Launch -eq "Y" -or $Launch -eq "y") {
                Write-Host "Launching RDP..." -ForegroundColor Cyan
                mstsc.exe /v:$IP
            }
        } else {
            Write-Host "You can now connect via SSH." -ForegroundColor Green
            Write-Host "Command: ssh $AdminUser@$IP" -ForegroundColor White
            
            $Launch = Read-Host "`nWould you like to attempt to launch SSH in this window? (Y/N)"
            if ($Launch -eq "Y" -or $Launch -eq "y") {
                ssh "$AdminUser@$IP"
            }
        }
    } else {
        Write-Host "`n[!] Connection timed out. The VM is likely still booting." -ForegroundColor Red
        Write-Host "Please try connecting manually to $IP in 1-2 minutes." -ForegroundColor White
    }    
}
