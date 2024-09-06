# pwnbox

## Manually build the image
```sh
docker build . -t ctfsetup
# Optional build args:
#   --build-arg FULL_BUILD=true
#   --build-arg WSL_BUILD=true
```


# Create WSL image from the container
```powershell
docker create --name wsl-temp ctfsetup
# This will take multiple minutes, and it has no progress meter
docker export wsl-temp -o wsl_rootfs.tar
docker rm wsl-temp

wsl --import pwnbox "$HOME/wsl_pwnbox" wsl_rootfs.tar

# pwnbox is automatically added to the profile
wsl -d pwnbox
```


