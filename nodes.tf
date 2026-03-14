resource "proxmox_virtual_environment_vm" "k0s_nodes" {
  count     = 3 # Change this number to scale your cluster
  name      = "k0s-node-${count.index}"
  node_name = var.proxmox_node_name

  # Clones from the template we defined in template.tf
  clone {
    vm_id = proxmox_virtual_environment_vm.k0s_template.vm_id
    full  = true
  }

  # Essential for Proxmox to see the IP and for k0sctl to work
  agent {
    enabled = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  network_device {
    bridge = var.network_bridge
  }

  initialization {
    # Custom DNS server as requested
    dns {
      servers = ["192.168.50.10"]
    }

    ip_config {
      ipv4 {
        # Starts at 192.168.80.20, then .21, then .22
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

# This output will show you the exact IPs in your terminal after you run 'apply'
output "k0s_node_ips" {
  value = [for vm in proxmox_virtual_environment_vm.k0s_nodes : vm.initialization[0].ip_config[0].ipv4[0].address]
}
