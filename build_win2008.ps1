$ErrorActionPreference = "Stop"

$virtualBoxMinVersion = "5.1.10"
$packerMinVersion = "0.10.0"
$vagrantMinVersion = "1.9.0"
$vagrantreloadMinVersion = "0.0.1"

function CompareVersions ($actualVersion, $expectedVersion, $exactMatch = $False) {
    If ($exactMatch) {
        If ($actualVersion -eq $expectedVersion) {
            return $True
        } else {
            return $False
        }
    }

    $actualVersion = $actualVersion.split(".")
    $expectedVersion = $expectedVersion.split(".")

    for($i=0; $i -le $expectedVersion.length; $i++) {
        If([INT]$actualVersion[$i] -gt [INT]$expectedVersion[$i]) {
            return $True
        }

        If([INT]$actualVersion[$i] -lt [INT]$expectedVersion[$i]) {
            return $False
        }
    }
    return $True
}

$expectedVBoxLocation = "C:\Program Files\Oracle\VirtualBox"
If ($(Test-Path "$expectedVBoxLocation\VBoxManage.exe") -eq $True) {
    $vboxVersion = cmd.exe /c "$expectedVBoxLocation\VBoxManage.exe" -v
    $vboxVersion = $vboxVersion.split("r")[0]
} else {
    Write-Host "VirtualBox is not installed (or not in the expected location of $expectedVBoxLocation\)"
    Write-Host "Please download and install it from https://www.virtualbox.org/"
    exit
}

If (CompareVersions -actualVersion $vboxVersion -expectedVersion $virtualBoxMinVersion -exactMatch $False) {
    Write-Host "Compatible version of VirtualBox found."
} else {
    Write-Host "A compatible version of VirtualBox was not found."
    Write-Host "Current Version=[$vboxVersion], Minimum Version=[$virtualBoxMinVersion]"
    Write-Host "Please download and install it from https://www.virtualbox.org/"
    exit
}

$packerVersion = cmd.exe /c "packer" -v

If (CompareVersions -actualVersion $packerVersion -expectedVersion $packerMinVersion) {
    Write-Host "Compatible version of packer found."
} else {
    Write-Host "Could not find a compatible version of packer. Please download it from https://www.packer.io/downloads.html and add it to your PATH."
    exit
}

If ($(Test-Path "C:\HashiCorp\Vagrant\bin\vagrant.exe") -eq $True) {
    $vagrantVersion = cmd.exe /c "vagrant" -v
    $vagrantVersion = $vagrantVersion.split(" ")[1]
}

If (CompareVersions -actualVersion $vagrantVersion -expectedVersion $vagrantMinVersion) {
    Write-Host "Compatible version of Vagrant found."
} else {
    Write-Host "Could not find a compatible version of Vagrant at C:\HashiCorp\Vagrant\bin\. Please download and install it from https://www.vagrantup.com/downloads.html."
    exit
}

$vagrantPlugins = cmd.exe /c "vagrant plugin list" | select-string -pattern "vagrant-reload"

If (![string]::IsNullOrEmpty($vagrantPlugins)) {
    $vagrantPlugins = $vagrantPlugins.ToString().Trim()
    $vagrantreloadVersion = $vagrantPlugins.Replace("(", "")
    $vagrantreloadVersion = $vagrantreloadVersion.Replace(")", "")
    $vagrantreloadVersion = $vagrantreloadVersion.split(" ")[1]

    If (CompareVersions -actualVersion $vagrantreloadVersion -expectedVersion $vagrantreloadMinVersion) {
        Write-Host "Compatible version of vagrant-reload plugin found."
    }
} else {
    Write-Host "Could not find a compatible version of vagrant-reload plugin. Attempting to install..."
    cmd.exe /c "vagrant plugin install vagrant-reload"

    # Hacky version of Try-Catch for non-terminating errors.
    # See http://stackoverflow.com/questions/1142211/try-catch-does-not-seem-to-have-an-effect
    if($?) {
        Write-Host "The vagrant-reload plugin was successfully installed."
    } else {
        throw "Error installing vagrant-reload plugin. Please check the output above for any error messages."
    }
}

Write-Host "All requirements found. Proceeding..."

If ($(Test-Path "windows_2008_r2_virtualbox.box") -eq $True) {
    Write-Host "It looks like the Vagrant box already exists. Skipping the Packer build."
} else {
    Write-Host "Building the Vagrant box..."
    cmd.exe /c packer build --only=virtualbox-iso windows_2008_r2.json

    if($?) {
        Write-Host "Box successfully built by Packer."
    } else {
        throw "Error building the Vagrant box using Packer. Please check the output above for any error messages."
    }
}

echo "Attempting to add the box to Vagrant..."

$vagrant_box_list = cmd.exe /c "vagrant box list" | select-string -pattern "metasploitable3"

If ($vagrant_box_list) { $vagrant_box_list = $vagrant_box_list.ToString().Trim() }

If ($vagrant_box_list -eq "metasploitable3") {
    Write-Host "metasploitable3 already found in Vagrant box repository. Skipping the addition to Vagrant."
} else {

    cmd.exe /c vagrant box add metasploitable3 windows_2008_r2_virtualbox.box

    if($?) {
        Write-Host "Box successfully added to Vagrant."
    } else {
        throw "Error adding box to Vagrant. See the above output for any error messages."
    }
}

Write-Host "SUCCESS: Run 'vagrant up' to provision and start metasploitable3."
Write-Host "NOTE: The VM will need Internet access to provision properly."