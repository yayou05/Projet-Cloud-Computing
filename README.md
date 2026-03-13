# Projet Cloud Computing

Projet IaC + automatisation pour deployer un backend Node.js sur Azure:

- Infrastructure avec Terraform (VM Linux, reseau, IP publique, Storage Account)
- Deploiement applicatif avec Ansible (Node.js, service systemd, variables d'environnement)
- API backend Express connectee a Azure Blob Storage

## Architecture

Ressources Azure provisionnees:

- Resource Group
- Virtual Network + Subnet
- Network Interface + Public IP
- Network Security Group (ports 22 et 3000)
- VM Linux Ubuntu 22.04
- Storage Account + conteneurs blobs `images` et `logs`

Backend deploye sur la VM:

- Application Node.js: `app/app.js`
- Service systemd: `backend-app`
- Variables env: `/etc/backend-app.env`

## Structure du projet

```text
Projet-Cloud-Computing/
	main.tf
	provider.tf
	variables.tf
	outputs.tf
	terraform.tfvars.example
	ansible/
		deploy_backend.yml
		inventory.ini.example
		group_vars/all.yml.example
		templates/backend.service.j2
		templates/backend-app.env.j2
	app/
		app.js
		package.json
```

## Prerequis

- Un abonnement Azure
- Terraform >= 1.0
- Ansible (recommande via WSL sur Windows)
- Acces SSH a la VM cible

## 1) Provisionner l'infrastructure (Terraform)

### Preparation

Copier le fichier d'exemple puis completer les valeurs:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Variables minimales a renseigner dans `terraform.tfvars`:

- `azure_subscription_id`
- `admin_password`
- `storage_account_name` (unique globalement, 3-24 caracteres minuscules)

### Deployment

```bash
terraform init
terraform plan
terraform apply
```

### Recuperer les sorties utiles

```bash
terraform output public_ip
terraform output backend_url
terraform output -raw storage_connection_string
terraform output -raw storage_account_primary_key
terraform output storage_account_name
```

## 2) Configurer Ansible

### Preparation des fichiers

```bash
cp ansible/inventory.ini.example ansible/inventory.ini
cp ansible/group_vars/all.yml.example ansible/group_vars/all.yml
```

### Inventory

Dans `ansible/inventory.ini`, verifier:

- IP publique de la VM
- `ansible_user`
- chemin de la cle SSH (`ansible_ssh_private_key_file`)

### Variables backend

Dans `ansible/group_vars/all.yml`, renseigner au minimum:

- `backend_port` (3000 par defaut)
- `backend_api_key` (recommande)
- `allowed_containers` (ex: `images,logs`)
- `azure_storage_connection_string`
- `azure_storage_account_name`
- `azure_storage_account_key`

## 3) Deployer l'application (Ansible)

Depuis le dossier racine du projet:

```bash
ansible-playbook -i ansible/inventory.ini ansible/deploy_backend.yml
```

Sur Windows avec WSL:

```bash
wsl -e bash -lc "cd '/mnt/c/Users/<user>/.../Projet-Cloud-Computing'; ansible-playbook -i ansible/inventory.ini ansible/deploy_backend.yml"
```

## 4) Verifier le service

Verification distante via Ansible:

```bash
ansible -i ansible/inventory.ini backend -m ping
ansible -i ansible/inventory.ini backend -m shell -a "systemctl is-active backend-app"
ansible -i ansible/inventory.ini backend -m shell -a "curl -s http://localhost:3000/health"
```

Verification directe (SSH):

```bash
sudo systemctl status backend-app --no-pager
journalctl -u backend-app -n 80 --no-pager
curl -s http://localhost:3000/health
```

## API Backend

Base URL:

```text
http://<PUBLIC_IP>:3000
```

Si `backend_api_key` est defini, envoyer le header:

```text
x-api-key: <votre-cle>
```

### Endpoints

- `GET /` : statut general
- `GET /health` : healthcheck
- `GET /files?container=<nom>` : liste des blobs
- `GET /files/:container/:blobName` : telechargement blob
- `POST /files/:container/:blobName` : upload (body JSON)
- `POST /files/:container/:blobName/sas` : generation d'URL SAS

### Exemple upload texte

```bash
curl -X POST "http://<PUBLIC_IP>:3000/files/images/hello.txt" \
	-H "Content-Type: application/json" \
	-H "x-api-key: <votre-cle>" \
	-d '{"content":"Bonjour Cloud","contentType":"text/plain"}'
```

### Exemple upload base64

```bash
curl -X POST "http://<PUBLIC_IP>:3000/files/images/image.bin?encoding=base64" \
	-H "Content-Type: application/json" \
	-H "x-api-key: <votre-cle>" \
	-d '{"content":"<BASE64_ICI>","contentType":"application/octet-stream"}'
```

### Exemple generation SAS

```bash
curl -X POST "http://<PUBLIC_IP>:3000/files/images/hello.txt/sas" \
	-H "Content-Type: application/json" \
	-H "x-api-key: <votre-cle>" \
	-d '{"permissions":"r","expiresInMinutes":30}'
```

## Securite

- Ne jamais commiter de secrets dans Git (`terraform.tfvars`, `ansible/group_vars/all.yml`)
- Utiliser des mots de passe forts et, idealement, l'authentification SSH par cle
- Limiter les ports exposes dans le NSG selon les besoins
- Utiliser `backend_api_key` en environnement reel

## Nettoyage des ressources

Pour supprimer toute l'infrastructure Azure creee par Terraform:

```bash
terraform destroy
```