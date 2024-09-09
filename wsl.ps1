
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

$download_attempt = iwr ((irm api.github.com/repos/obarroncs/pwnbox/releases/latest | % assets)[0].browser_download_url) -OutFile $out_file_name

if (-not $?){
    Write-Output "Failed to download image"
    exit 1
}

$output = wsl --import $distro_name "$HOME/wsl_managed_pwnbox_timestamp" $out_file_name 2>&1

if ($?) {
    Write-Output "Successfully installed pwnbox"
    Write-Output "Name: $distro_name"
} else {
    Write-Output "Import failed: $output"
}


