
function Get-DistroName {
    param (
        [string]$base_name
    )
    $counter = 1
    $unique_name = $base_name
    $all_distros = wsl -l -q

    while ($all_distros -contains $unique_name) {
        $unique_name = "$base_name-$counter"
        $counter++
    }

    return $unique_name
}

$base_name = "pwnbox"
$distro_name = Get-DistroName -base_name $base_name

$timestamp = (Get-Date).ToString("yyyyMMddHHmmss")
$out_file_name = "wsl_rootfs_$timestamp.tar.gz"

Write-Output "Downloading the latest release file for the WSL root filesystem"
Write-Output "The file is about 2GB - writing to $pwd\$out_file_name"
Import-Module BitsTransfer

$download_url = (irm api.github.com/repos/obarroncs/pwnbox/releases/latest | % assets)[0].browser_download_url

Write-Output "Starting file download: $download_url"
$download_attempt = Start-BitsTransfer $download_url -Destination $out_file_name

if (-not $?){
    Write-Output "Failed to download the pre-built root filesystem"
    exit 1
}

Write-Output "Creating a WSL distro with file: $out_file_name"
Write-Output "Running the following command:"
Write-Output ""
Write-Output "wsl --import $distro_name "$HOME/wsl_managed_pwnbox_timestamp" $out_file_name 2>&1"
Write-Output ""
Write-Output "This may take a moment"
wsl --import $distro_name "$HOME/wsl_managed_pwnbox_$timestamp" $out_file_name 2>&1

if ($?) {
    Write-Output "Successfully installed pwnbox"
    Write-Output "Name: $distro_name"
    Write-Output "Use it by running the command: 'wsl -d $distro_name'"
    Write-Output "It's also been added to your Windows Terminal profile - restart the Terminal to see it"
} else {
    Write-Output "Import failed: $output"
}


