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


resource "yandex_compute_instance" "consul-01" {
  name     = "consul-01"
  hostname = "consul-01"

  resources {
    cores  = 2
    memory = 2
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




output "consul_01_ansible_host" {
  value = yandex_compute_instance.consul-01.network_interface.0.nat_ip_address
}


resource "yandex_compute_instance" "consul-02" {
  name     = "consul-02"
  hostname = "consul-02"

  resources {
    cores  = 2
    memory = 2
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




output "consul_02_ansible_host" {
  value = yandex_compute_instance.consul-02.network_interface.0.nat_ip_address
}


resource "yandex_compute_instance" "consul-03" {
  name     = "consul-03"
  hostname = "consul-03"

  resources {
    cores  = 2
    memory = 2
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




output "consul_03_ansible_host" {
  value = yandex_compute_instance.consul-03.network_interface.0.nat_ip_address
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



output "pg_teach_01_ansible_host" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}




resource "yandex_compute_instance" "vm-2" {
  name     = "pg-teach-02"
  hostname = "pg-teach-02"

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



output "pg_teach_02_ansible_host" {
  value = yandex_compute_instance.vm-2.network_interface.0.nat_ip_address
}


resource "yandex_compute_instance" "vm-3" {
  name     = "pg-teach-03"
  hostname = "pg-teach-03"

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



output "pg_teach_03_ansible_host" {
  value = yandex_compute_instance.vm-3.network_interface.0.nat_ip_address
}




