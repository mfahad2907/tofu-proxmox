variable "proxmox_endpoint" {
  type    = string
  default = "https://192.168.80.14:8006/" # <--- Your Proxmox IP
}

variable "proxmox_api_token" {
  type      = string
  sensitive = true
  default   = "terraform@pve!provisioner=1c442791-b012-441c-b0da-96215479e2a9" # <--- Your Token
}

variable "proxmox_node_name" {
  type    = string
  default = "server04"
}

variable "ssh_public_key" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCwp2LzcPGhJ3or+08v+YESykwuuMGnvU2/nNcU2ZBLGVOqErXUom+Q+ForBTtquohmMs1RpKB2PryYAssYoPG9nEwcJWZOB3YPL4XTjh9IgeZaQnm/fr6y4qYHp5+MAdePGHMiKse/yE0uUWra8kUiYe2KgkpkukddvxaCjA5LI75+/9VAtuNM2dIWrEUfZ7R6s/eE8iQ2faIfMyTU5QOUNI5/goUflMyP3gaIxi8nUZ9jkfj09agRSKl2dwamatbzR3IiAqxkaWaTk01ctOwSxW3vsH2GuHx5MS45ipSDv7ppBYh8oLuJCE1vVbM2TbBgF/j0vyVp0JV3w7JqTS0dh7hkMSekLiNTj/KfovymUnlo1Xq7b56cD8nvh2bXVqo/IiH7ArQ7vIoabSaBUPllGeF/BkvVQqYIBwEiKiwc3vcj6R45dXV96VpfAq382s675+b5jLRFGBGqAJBgpogflE+Vrs/1cV0cT7mOHFYbnvaOSf28OBHANMMuS8tGbTh9xMW/AgCSc7ZK31g6B3wOZbYxrxptR8nax3XnFXAYWjcEE2U8eS+P0LE/UltLNFnupz1+l9u5IcJbqwCrr8qV0CZwffaQL3+Yo+7kMQ2Uw7Te1BHvs0C8vKWfTzQ0XjwujvaN+lQdiEhTcT5nUTOufkvXfyfs77TlzOjNTiJUBQ== ri@ri-t-1005" 
}

variable "network_bridge" {
  type    = string
  default = "vmbr80"
}
