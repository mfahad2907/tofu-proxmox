terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc07"
    }

  }
}

provider "proxmox" {
  pm_tls_insecure = true
  pm_api_url      = "https://192.168.80.14:8006/api2/json"
  pm_api_token_secret  = "1c442791-b012-441c-b0da-96215479e2a9"
  pm_api_token_id = "terraform@pve!provisioner"
}

resource "proxmox_vm_qemu" "cloudinit-test" {
  count = 3
  vmid = "20${count.index}"
  name        = "terraform-test-vm-${count.index}"
  description = "A test for using terraform and cloudinit"

  # Node name has to be the same name as within the cluster
  # this might not include the FQDN
  target_node = "server04"


  # The template name to clone this vm from
  clone = "k0s-template"
  agent = 1

  os_type = "cloud-init"

  cpu {
    cores   = 2
    sockets = 1
    type    = "host"
  }
  memory = 2048

  # Setup the disk
  disks {
    ide {
      ide3 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
    virtio {
      virtio0 {
        disk {
          size         = 40
          storage      = "local-lvm"
          discard      = true
        }
      }
    }
  }

  # Setup the network interface and assign a vlan tag: 256
  network {
    id = 0
    model  = "virtio"
    bridge = "vmbr80"
  }

  # Setup the ip address using cloud-init.
  boot = "order=virtio0"
  # Keep in mind to use the CIDR notation for the ip.
  ipconfig0 = "ip=192.168.80.20/24,gw=192.168.80.1"

  sshkeys = <<EOF
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCwp2LzcPGhJ3or+08v+YESykwuuMGnvU2/nNcU2ZBLGVOqErXUom+Q+ForBTtquohmMs1RpKB2PryYAssYoPG9nEwcJWZOB3YPL4XTjh9IgeZaQnm/fr6y4qYHp5+MAdePGHMiKse/yE0uUWra8kUiYe2KgkpkukddvxaCjA5LI75+/9VAtuNM2dIWrEUfZ7R6s/eE8iQ2faIfMyTU5QOUNI5/goUflMyP3gaIxi8nUZ9jkfj09agRSKl2dwamatbzR3IiAqxkaWaTk01ctOwSxW3vsH2GuHx5MS45ipSDv7ppBYh8oLuJCE1vVbM2TbBgF/j0vyVp0JV3w7JqTS0dh7hkMSekLiNTj/KfovymUnlo1Xq7b56cD8nvh2bXVqo/IiH7ArQ7vIoabSaBUPllGeF/BkvVQqYIBwEiKiwc3vcj6R45dXV96VpfAq382s675+b5jLRFGBGqAJBgpogflE+Vrs/1cV0cT7mOHFYbnvaOSf28OBHANMMuS8tGbTh9xMW/AgCSc7ZK31g6B3wOZbYxrxptR8nax3XnFXAYWjcEE2U8eS+P0LE/UltLNFnupz1+l9u5IcJbqwCrr8qV0CZwffaQL3+Yo+7kMQ2Uw7Te1BHvs0C8vKWfTzQ0XjwujvaN+lQdiEhTcT5nUTOufkvXfyfs77TlzOjNTiJUBQ== ri@ri-t-1005
    EOF
}