terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
}


resource "yandex_compute_instance" "vm-1" {
  name     = "pg-teach-01"
  hostname = "pg-teach-01"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8ebb4u1u8mc6fheog1"
      size     = "10"
      type     = "network-ssd"
    }
  }



  network_interface {
    subnet_id = "e9b76q9b573881psop2r"
    nat = true
  }

  metadata = {
    user-data = "${file("/home/aslepov/aslepov_repo/pgdb_teach/project/yc/access/meta.txt")}"
  }


}



output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.ip_address
}


output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}
