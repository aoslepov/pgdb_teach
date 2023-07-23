
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

[https://github.com/aoslepov/pgdb_teach/blob/main/project/yc/main.tf](main.tf)



https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart
