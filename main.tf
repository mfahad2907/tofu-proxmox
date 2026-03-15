terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.70.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true
  ssh {
    agent    = true
    username = "root"
  }
}

# --- TEMPLATE SECTION ---
resource "proxmox_virtual_environment_download_file" "ubuntu_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_node_name
  file_name    = "ubuntu-24.04-cloud.img"
  url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

resource "proxmox_virtual_environment_vm" "k0s_template" {
  name      = "k0s-template"
  node_name = var.proxmox_node_name
  vm_id     = 900
  template  = true

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_image.id
    interface    = "virtio0"
    size         = 20
  }

  initialization {
    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }
  }

  network_device {
    bridge = var.network_bridge
  }
}

# --- NODES SECTION ---
resource "proxmox_virtual_environment_vm" "k0s_nodes" {
  count     = 3
  vm_id     = 200 + count.index
  name      = "k0s-node-${count.index}"
  node_name = var.proxmox_node_name

  clone {
    vm_id = proxmox_virtual_environment_vm.k0s_template.vm_id
    full  = true # Essential for local-lvm compatibility
  }

  agent { enabled = true }
  cpu   { cores = 2 }
  memory { dedicated = 2048 }

  network_device {
    bridge = var.network_bridge
  }

  initialization {
    datastore_id = "local-lvm"
    dns {
      servers = ["192.168.50.10"]
    }
    ip_config {
      ipv4 {
        # Results in .20, .21, .22
        address = "192.168.80.${20 + count.index}/24"
        gateway = "192.168.80.1"
      }
    }
    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }
  }
}

