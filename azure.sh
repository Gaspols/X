#!/usr/bin/env bash
while getopts g:u:p:s:t: flag
do
    case "${flag}" in
        g) resource_group=${OPTARG};;
        u) user=${OPTARG};;
        p) pass=${OPTARG};;
        s) size=${OPTARG};;
        t) total=${OPTARG};;
    esac
done
all_locations=("centralus" "eastus" "eastus2" "westus" "westus2" "northcentralus" "southcentralus" "westcentralus" "northeurope" "westeurope" "canadacentral" "canadaeast" "uksouth" "ukwest" "francecentral" "australiasoutheast" "australiaeast" "australiacentral" "switzerlandnorth" "germanywestcentral" "norwayeast" "westus3" "swedencentral" "uaenorth" "koreacentral" "koreasouth" "japaneast" "japanwest" "brazilsouth" "westindia" "southindia" "centralindia" "southafricanorth" "eastasia" "southeastasia")
COUNTER=0
IPS=()
VMS=()
LCS=()
for location in ${all_locations[@]}; do
    ll=$(az vm list-skus -l westeurope --size $size --query "[].name" --output tsv)
    if [[$COUNTER -eq $total]]; then
        break
    elif [ -z "$ll" ]; then
        az vm list-skus -l westeurope --size $size --query "[].name" --output tsv
        COUNTER=$[$COUNTER +1]
        vm_name="s$COUNTER"
        VMS+=($vm_name)
        LCS+=(westeurope)
        az group create -l westeurope -n $resource_group --output none
        az vm create -g $resource_group -n $vm_name --image Canonical:0001-com-ubuntu-server-focal:20_04-lts:latest --admin-username $user --admin-password $pass --generate-ssh-keys --size $size --location westeurope --public-ip-sku Basic --public-ip-address-allocation static --output none
        echo "set root access for $vm_namme..."
        az vm run-command invoke -g $resource_group -n $vm_name --command-id RunShellScript --scripts "echo 'root:$pass' | sudo chpasswd && sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && sudo service ssh restart" --output none
        echo "open all port for $vm_namme..."
        az vm open-port -g $resource_group -n $vm_name --port "*" --priority 100 --output none
        pubip="${vm_name}PublicIP"
        IPS+=($(az network public-ip show -g $resource_group -n $pubip --query 'ipAddress' --output tsv))
    fi
done
if [ -z "$IPS" ]; then
    echo "resource group : $resource_group"
    echo "vm size : $size"
    for i in $(seq 1 $total); do
        echo "${VMS[$i]} : ${LCS[$i]}|${IPS[$i]}"
    done
    echo "admin : root"
    echo "user : $user"
    echo "pass : $pass"
else
    echo "No vps created"
fi
