# Azure Terraform Project: Deploy Open Web UI VM

## Overview

This project demonstrates how to use Terraform to provision a Virtual Machine (VM) on Azure, install Docker, and deploy [Open Web UI](https://github.com/open-webui/open-webui) for local LLM and RAG workflows. It supports both CPU and GPU VM types and can integrate with OpenAI APIs.

---

## Architecture

- **Resource Group**: All resources are grouped for easy management.
- **Virtual Network & Subnet**: Isolated network for the VM.
- **Public IP**: Static IP for external access.
- **Network Interface**: Connects VM to the network.
- **Network Security Group**: Controls inbound/outbound traffic (SSH, HTTP, etc).
- **Linux Virtual Machine**: Debian-based VM, provisioned via cloud-init.
- **Cloud-init**: Runs scripts to install Docker, Open Web UI, and configure admin user.
- **Random Password**: Secure password for the web UI admin.
- **Outputs**: Exposes VM public IP, private IP, and admin password.

---

## File Structure

```
main.tf                # Terraform variables and providers
output.tf              # Outputs for IPs and password
vm.tf                  # Main resource definitions
scripts/
  provision_basic.sh   # Cloud-init script for basic setup
  provision_vars.sh    # Cloud-init script with variable support (GPU, OpenAI)
  init.yaml            # Cloud-init config
```

---

## Variables

| Name                | Default                | Description                                      |
|---------------------|------------------------|--------------------------------------------------|
| `open_webui_user`   | admin@demo.gs          | Username for Open Web UI                         |
| `openai_base`       | https://api.openai.com/v1 | Base URL for OpenAI API                      |
| `openai_key`        | ""                     | OpenAI API Key                                   |
| `machine`           | See `main.tf`          | VM size/type for CPU or GPU                      |
                     

---

## Security

- **Credentials**: Never hardcode Azure credentials. Use environment variables:
  ```sh
  export ARM_CLIENT_ID="xxxx"
  export ARM_SUBSCRIPTION_ID="xxxx"
  export ARM_TENANT_ID="xxxx"
  export ARM_CLIENT_SECRET="xxxx"
  ```
- **Sensitive Outputs**: Password output is marked sensitive.
- **.gitignore**: Excludes secrets, state files, and sensitive configs.

---

## Provisioning Flow

1. **Terraform Apply**: Creates all Azure resources.
2. **Cloud-init**: Runs `provision_vars.sh` or `provision_basic.sh` on VM boot.
3. **Docker & Open Web UI**: Installed and started as a systemd service.
4. **Admin User**: Created in SQLite DB before first run.
5. **GPU Support**: Installs Nvidia drivers and container toolkit if enabled.
6. **OpenAI Integration**: API key and base URL passed via environment file.

---

## Usage

### Prerequisites

- Azure account with permissions
- Terraform CLI installed
- SSH key at `~/.ssh/id_rsa.pub` (or modify path in `vm.tf`)

### Steps

1. **Set Azure Credentials**
   ```sh
   export ARM_CLIENT_ID="xxxx"
   export ARM_SUBSCRIPTION_ID="xxxx"
   export ARM_TENANT_ID="xxxx"
   export ARM_CLIENT_SECRET="xxxx"
   ```

2. **(Optional) Set OpenAI Variables**
   ```sh
   export TF_VAR_openai_key="sk-..."
   export TF_VAR_openai_base="https://api.openai.com/v1"
   ```

3. **Initialize Terraform**
   ```sh
   terraform init
   ```

4. **Apply Configuration**
   ```sh
   terraform apply
   # or
   terraform apply -auto-approve
   ```

5. **Get Outputs**
   ```sh
   terraform output vm_public_ip
   terraform output password
   ```

6. **Access VM**
   ```sh
   ssh openwebui@$(terraform output --raw vm_public_ip)
   ```

7. **Access Web UI**
   - Open browser to `http://<vm_public_ip>`
   - Login with username (`open_webui_user`) and password (`terraform output password`)

---

## Troubleshooting

- **VM Not Accessible**: Check NSG rules for SSH/HTTP.
- **Docker Not Running**: SSH to VM and run `sudo systemctl status openwebui.service`.
- **Cloud-init Errors**: Check `/var/log/cloud-init.log` on VM.
- **GPU Issues**: Ensure VM size supports GPU and drivers are installed.

---

## Cleaning Up

To destroy all resources:
```sh
terraform destroy
```

---

## References

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Open Web UI](https://github.com/open-webui/open-webui)
- [Cloud-init](https://cloudinit.readthedocs.io/en/latest/)
- [Azure VM Sizes](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes)

---

## Customization

- Change VM size/types in `main.tf` variable `machine`.
- Modify `scripts/provision_vars.sh` for custom setup.
- Add more NSG rules in `vm.tf` as needed.

---

## License

See [LICENSE](.terraform/modules/network-security-group/LICENSE) for details.
ssh -i ~/.ssh/id_rsa openwebui@4.180.182.22