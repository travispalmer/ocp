az group create -n ocp-wusqa0-rg -l westus
az keyvault create -n wusqa0-keyvault -g ocp-wusqa0-rg -l westus --enabled-for-template-deployment true
az keyvault secret set --vault-name WUSQA0-KeyVault -n SSHPrivateKey --file C:\Users\tpalmer\temp\wusqa0\OCPPrivateKey.pem

az keyvault secret set --vault-name WUSQA0-KeyVault -n mastercafile --file C:\Users\tpalmer\temp\wusqa0\NVLCMBM100CA.pem
az keyvault secret set --vault-name WUSQA0-KeyVault -n mastercertfile --file C:\Users\tpalmer\temp\wusqa0\master.cer
az keyvault secret set --vault-name WUSQA0-KeyVault -n masterkeyfile --file C:\Users\tpalmer\temp\wusqa0\master.key

az keyvault secret set --vault-name WUSQA0-KeyVault -n routingcafile --file C:\Users\tpalmer\temp\wusqa0\NVLCMBM100CA.pem
az keyvault secret set --vault-name WUSQA0-KeyVault -n routingcertfile --file C:\Users\tpalmer\temp\wusqa0\router.cer
az keyvault secret set --vault-name WUSQA0-KeyVault -n routingkeyfile --file C:\Users\tpalmer\temp\wusqa0\router.key

