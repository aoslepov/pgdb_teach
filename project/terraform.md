
Установка terraform и yandex cloud

```
* устанавливаем terraform 
sudo wget -qO- https://hashicorp-releases.yandexcloud.net/terraform/1.5.3/terraform_1.5.3_linux_amd64.zip | gunzip - > /usr/local/sbin/terraform
sudo chmod +x /usr/local/sbin/terraform

* устанавливаем yandex cloud
cd /usr/local/sbin/
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash

* Получаем токен yandex cloud
https://oauth.yandex.ru/authorize?response_type=token&client_id=1a6990aa636648e9b2ef855fa7bec2fb

* Проверяем установку yc config list

* cоздаём сервисный аккаунт для api yc
yc iam service-account create --name yc-terraform

yc iam service-account list
+----------------------+--------------+
|          ID          |     NAME     |
+----------------------+--------------+
| ajelke70oe4djhng98qn | yc-terraform |
+----------------------+--------------+

* выгружаема ключ для доступа к созданному сервисному аккаунту
yc iam key create --service-account-id ajelke70oe4djhng98qn  --folder-name default  --output key.json

* создаём профиль yc для сервисного аккаунта
yc config profile create yc-terraform


* создаём скрипт для подключения к сервисному аккаунту через апи
-- получем токен
export YC_TOKEN=$(yc iam create-token)
-- получаей идентификатор yc
export YC_CLOUD_ID=$(yc config get cloud-id)
-- получаем индетификатор папки (default)
export YC_FOLDER_ID=$(yc config get folder-id)

*Инициализируем провайдер yandex-cloud для terraform*
> yc_init.tr

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

* Запускаем terraform init в папке с конфигом

```

*Собираем информацию для формирования плана запроса*
```


* находим id образа дистрибутива
yc compute image list --folder-id standard-images | grep ubuntu-22-04 | grep 20230 
| fd8ebb4u1u8mc6fheog1 | ubuntu-22-04-lts-v20230626a

-- получаем список айдишек для подсетей
yc vpc network list-subnets --name default
+----------------------+-----------------------+----------------------+----------------------+----------------+---------------+-----------------+
|          ID          |         NAME          |      FOLDER ID       |      NETWORK ID      | ROUTE TABLE ID |     ZONE      |      RANGE      |
+----------------------+-----------------------+----------------------+----------------------+----------------+---------------+-----------------+
| b0cdp7n3i6thfhi209fe | default-ru-central1-c | b1g7jn3kmfd43b53ui4s | enpfqa8mj3jnlp1qitno |                | ru-central1-c | [10.130.0.0/24] |
| e2lnu92uiq65p8jm4ulf | default-ru-central1-b | b1g7jn3kmfd43b53ui4s | enpfqa8mj3jnlp1qitno |                | ru-central1-b | [10.129.0.0/24] |
| e9b76q9b573881psop2r | default-ru-central1-a | b1g7jn3kmfd43b53ui4s | enpfqa8mj3jnlp1qitno |                | ru-central1-a | [10.128.0.0/24] |
+----------------------+-----------------------+----------------------+----------------------+----------------+---------------+----------------


нас интересует подсеть default-ru-central1-a


* Создаём файл для доступа к вм по ssh с нужным правами 
> meta.txt

#cloud-config
users:
  - name: aslepov
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - ssh-rsa XXX

```

Создание плана для будуших вм
<https://github.com/aoslepov/pgdb_teach/blob/main/project/yc/main.tf>

```
* Проверяем синтаксис плана
terraform validate 


* Смотрим составленный план
terraform plan


Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_instance.vm-1 will be created
  + resource "yandex_compute_instance" "vm-1" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hostname                  = "pg-teach-01"
      + id                        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: aslepov
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh-authorized-keys:
                      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKPUc0Hs7AHn9PdxPOmNngvpecgorKRMK0BIZLTRadaA7UYSMth7T4UfxgNAPm2OXnbCmjU9IItsyhLzdYXJt3V4nyZP9AN05FSYWq60baRSbjWllf5Nqsb5AC4edFLl7dLZJGKlGn5bVUdlfZOb7d5+OBW9PH+kxT5Zs/iJ+bFSpuU7G2hK+9R8bI31uokYh8Qb7Ku02GZyHDIVsAW7P1yZ2zcIZlyuaTjfciFobBi0OI9rWNbDq5R4LribaNNZpw5jQ5gYgh0aqahhnW3u635pZsjoWjz6m6ueuZmVCUFU9Z1R3AvHKnhFiNLP6arB9hpUgKsAZF+kb3tl7MhlwF
            EOT
        }
      + name                      = "pg-teach-01"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = (known after apply)

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8ebb4u1u8mc6fheog1"
              + name        = (known after apply)
              + size        = 10
              + snapshot_id = (known after apply)
              + type        = "network-ssd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = "e9b76q9b573881psop2r"
        }

      + resources {
          + core_fraction = 100
          + cores         = 2
          + memory        = 4
        }
    }

  # yandex_compute_instance.vm-2 will be created
  + resource "yandex_compute_instance" "vm-2" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hostname                  = "pg-teach-02"
      + id                        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: aslepov
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh-authorized-keys:
                      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKPUc0Hs7AHn9PdxPOmNngvpecgorKRMK0BIZLTRadaA7UYSMth7T4UfxgNAPm2OXnbCmjU9IItsyhLzdYXJt3V4nyZP9AN05FSYWq60baRSbjWllf5Nqsb5AC4edFLl7dLZJGKlGn5bVUdlfZOb7d5+OBW9PH+kxT5Zs/iJ+bFSpuU7G2hK+9R8bI31uokYh8Qb7Ku02GZyHDIVsAW7P1yZ2zcIZlyuaTjfciFobBi0OI9rWNbDq5R4LribaNNZpw5jQ5gYgh0aqahhnW3u635pZsjoWjz6m6ueuZmVCUFU9Z1R3AvHKnhFiNLP6arB9hpUgKsAZF+kb3tl7MhlwF
            EOT
        }
      + name                      = "pg-teach-02"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = (known after apply)

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8ebb4u1u8mc6fheog1"
              + name        = (known after apply)
              + size        = 10
              + snapshot_id = (known after apply)
              + type        = "network-ssd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = "e9b76q9b573881psop2r"
        }

      + resources {
          + core_fraction = 100
          + cores         = 2
          + memory        = 4
        }
    }

  # yandex_compute_instance.vm-3 will be created
  + resource "yandex_compute_instance" "vm-3" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hostname                  = "pg-teach-03"
      + id                        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: aslepov
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh-authorized-keys:
                      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKPUc0Hs7AHn9PdxPOmNngvpecgorKRMK0BIZLTRadaA7UYSMth7T4UfxgNAPm2OXnbCmjU9IItsyhLzdYXJt3V4nyZP9AN05FSYWq60baRSbjWllf5Nqsb5AC4edFLl7dLZJGKlGn5bVUdlfZOb7d5+OBW9PH+kxT5Zs/iJ+bFSpuU7G2hK+9R8bI31uokYh8Qb7Ku02GZyHDIVsAW7P1yZ2zcIZlyuaTjfciFobBi0OI9rWNbDq5R4LribaNNZpw5jQ5gYgh0aqahhnW3u635pZsjoWjz6m6ueuZmVCUFU9Z1R3AvHKnhFiNLP6arB9hpUgKsAZF+kb3tl7MhlwF
            EOT
        }
      + name                      = "pg-teach-03"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = (known after apply)

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8ebb4u1u8mc6fheog1"
              + name        = (known after apply)
              + size        = 10
              + snapshot_id = (known after apply)
              + type        = "network-ssd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = "e9b76q9b573881psop2r"
        }

      + resources {
          + core_fraction = 100
          + cores         = 2
          + memory        = 4
        }
    }

Plan: 3 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + external_ip_address_vm_1 = (known after apply)
  + external_ip_address_vm_2 = (known after apply)
  + external_ip_address_vm_3 = (known after apply)
  + internal_ip_address_vm_1 = (known after apply)
  + internal_ip_address_vm_2 = (known after apply)
  + internal_ip_address_vm_3 = (known after apply)

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now

```

* Развёртывание вм согластно плану terraform apply



https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart
