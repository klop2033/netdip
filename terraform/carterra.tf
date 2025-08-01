#считываем данные об образе ОС
data "yandex_compute_image" "ubuntu_2204_lts" {
  family = "ubuntu-2204-lts"
}

data "yandex_compute_image" "debian-12"{
  family = "debian-12"
}
# Создаем и размещаем VPS в разных зонах
# создем VPS stena с белым ip, и во внутренней сетке web-server 1 в зоне А, web-server 2 в зоне Б.
### Создание VPS "bastion"


resource "yandex_compute_instance" "bastion" {
  name        = "bastion" #Имя ВМ в облачной консоли
  hostname    = "bastion" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-a" #зона ВМ должна совпадать с зоной subnet!!! ( VPS создаеться в netologydz_a )
  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.debian-12.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {                                      #Файл с SHH ключами.Ниже пример перекинь в другой файл
    user-data          = file("./cloud-init.yml")   # Создай "name.yml"
    serial-port-enable = 1
  }
  
  scheduling_policy { preemptible = false }  # Прерываемость VPS (Вырубиться через 24 часа)

  network_interface {
    subnet_id          = yandex_vpc_subnet.diplom_a.id #зона ВМ должна совпадать с зоной subnet!!!
    nat                = true
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.bastion.id]
  }
}
### Конец VPS "bastiona" ###

### web-server 1 ###
resource "yandex_compute_instance" "nginx1" {
  name        = "nginx1" #Имя ВМ в облачной консоли
  hostname    = "nginx1" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-a" #зона ВМ должна совпадать с зоной subnet!!! ( VPS создаеться netologydz_a )
  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {                                      #Файл с SHH ключами.Ниже пример перекинь в другой файл
    user-data          = file("./cloud-init.yml")   # Создай "name.yml"
    serial-port-enable = 1
  }
  
# cloud-config
# users:
#   - name: user                        #                     #
#     groups: sudo                      #Создает пользователя #
#     shell: /bin/bash                  #и выдает права SUDO  #
#     sudo: ["ALL=(ALL) NOPASSWD:ALL"]  #                     #
#     ssh_authorized_keys:
#       - ##Сюда ключ ssh-ed25519 ##


  scheduling_policy { preemptible = false }  # Прерываемость VPS (Вырубиться через 24 часа)

  network_interface {
    subnet_id          = yandex_vpc_subnet.diplom_a.id #зона ВМ должна совпадать с зоной subnet!!!
    nat                = false
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.web_sg.id]
  }
}
### Конец VPS web-server 1 ###


### Начало VPS web-server 2 ###
resource "yandex_compute_instance" "nginx2" {
  name        = "nginx2" #Имя ВМ в облачной консоли
  hostname    = "nginx2" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-b" #зона ВМ должна совпадать с зоной subnet!!!
  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")   #Файл с SHH ключами.
    serial-port-enable = 1                          # Включение консоли в облаке
  }

  scheduling_policy { preemptible = false }  # Прерываемость VPS (Вырубиться через 24 часа)

  network_interface {
    subnet_id          = yandex_vpc_subnet.diplom_b.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.web_sg.id]
  }
}

### Начало VPS Elastik ###
resource "yandex_compute_instance" "elastik" {
  name        = "elastik" #Имя ВМ в облачной консоли
  hostname    = "elastik" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-b" #зона ВМ должна совпадать с зоной subnet!!!
  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")   #Файл с SHH ключами.
    serial-port-enable = 1                          # Включение консоли в облаке
  }

  scheduling_policy { preemptible = false }  # Прерываемость VPS (Вырубиться через 24 часа)

  network_interface {
    subnet_id          = yandex_vpc_subnet.diplom_b.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.web_sg.id]
    
  }
}


##### Zabbix
resource "yandex_compute_instance" "zabbix" {
  name        = "zabbix" #Имя ВМ в облачной консоли
  hostname    = "zabbix" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-b" #зона ВМ должна совпадать с зоной subnet!!! ( VPS создаеться в netologydz_a )
  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.debian-12.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {                                      #Файл с SHH ключами.Ниже пример перекинь в другой файл
    user-data          = file("./cloud-init.yml")   # Создай "name.yml"
    serial-port-enable = 1
  }
  
  scheduling_policy { preemptible = false }  # Прерываемость VPS (Вырубиться через 24 часа)

  network_interface {
    subnet_id          = yandex_vpc_subnet.diplom_b.id #зона ВМ должна совпадать с зоной subnet!!!
    nat                = true
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.zabbix.id]
  }
}
### Конец VPS "zabbix" ###
### Начало Kibana ###

resource "yandex_compute_instance" "kibana" {
  name        = "kibana" #Имя ВМ в облачной консоли
  hostname    = "kibana" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-a" #зона ВМ должна совпадать с зоной subnet!!! ( VPS создаеться в netologydz_a )
  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {                                      #Файл с SHH ключами.Ниже пример перекинь в другой файл
    user-data          = file("./cloud-init.yml")   # Создай "name.yml"
    serial-port-enable = 1
  }
  
  scheduling_policy { preemptible = false }  # Прерываемость VPS (Вырубиться через 24 часа)

  network_interface {
    subnet_id          = yandex_vpc_subnet.diplom_a.id #зона ВМ должна совпадать с зоной subnet!!!
    nat                = true
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.kibana.id]
  }
}
### Конец VPS "kibana" ###