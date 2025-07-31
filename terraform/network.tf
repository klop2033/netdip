###############Переменные#########################    Можно разбить по файлам Terraform сожрет
variable "cloud_id" {
    type=string
    default="b1gtm33iqcnv4kbjpll8" #Из личного кабинета YC
}
variable "folder_id" {
    type=string
    default="b1ggou49esjloni8jfof" #Из личного кабинета YC
}

variable "test" {                  # Технические характеристики виртуальных машин
    type=map(number)
    default={
    cores         = 2              # Количество ядер 
    memory        = 2              # объем оперативной памяти
    core_fraction = 5             # 5-20-100% выбрать нужный
  }
}
################Переменные сверху#################
### Авторизация в облаке ###
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.129.0"
    }
  }

  required_version = ">=1.8.4"
}

provider "yandex" {
  # token                    = "do not use!!!"
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  service_account_key_file = file("./authorized_key.json") #ключ сгенерированный в облаке
}
#######

#создаем облачную сеть
resource "yandex_vpc_network" "diplom" {
  name = "diplom"
}


#создаем подсеть zone A netologydz_a создаеться в diplom
resource "yandex_vpc_subnet" "diplom_a" {
  name           = "diplom-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom.id
  v4_cidr_blocks = ["10.10.12.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}
#######



#создаем подсеть zone B netologydz_b создаеться в diplom
resource "yandex_vpc_subnet" "diplom_b" {
  name           = "diplom-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.diplom.id
  v4_cidr_blocks = ["10.10.11.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}
###

#создаем NAT для выхода в интернет
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "fops-gateway"
  shared_egress_gateway {}
}

#создаем сетевой маршрут для выхода в интернет через NAT
resource "yandex_vpc_route_table" "rt" {
  name       = "fops-route-table"
  network_id = yandex_vpc_network.diplom.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

#создаем группы безопасности(firewall)

resource "yandex_vpc_security_group" "bastion" {
  name       = "bastion-sg"
  network_id = yandex_vpc_network.diplom.id
  ingress {
    description    = "Allow 0.0.0.0/0"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

}

#создаем группы безопасности(zabbix)

resource "yandex_vpc_security_group" "zabbix" {
  name       = "zabbix-web"
  network_id = yandex_vpc_network.diplom.id
  ingress {
    description    = "Allow 0.0.0.0/0"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8080
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

}


#создаем группы безопасности(kibana)

resource "yandex_vpc_security_group" "kibana" {
  name       = "kibana-web"
  network_id = yandex_vpc_network.diplom.id
  ingress {
    description    = "Allow 0.0.0.0/0"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

}

resource "yandex_vpc_security_group" "LAN" {
  name       = "LAN-sg"
  network_id = yandex_vpc_network.diplom.id
  ingress {
    description    = "Allow 10.0.0.0/8"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.0.0.0/8"]
    from_port      = 0
    to_port        = 65535
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

}

resource "yandex_vpc_security_group" "web_sg" {
  name       = "web-sg"
  network_id = yandex_vpc_network.diplom.id

  ingress {
    protocol       = "TCP"
    description    = "Health checks from Yandex ALB"
    port           = 80  # или порт, который вы используете для health-проверок
    v4_cidr_blocks = ["198.18.235.0/24", "198.18.248.0/24"]  # Диапазоны IP для health-проверок
  }
    # Разрешаем доступ к балансировщику на порту 9000
  ingress {
    protocol       = "TCP"
    description    = "ALB listener access"
    port           = 9000
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description    = "Allow HTTPS"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description    = "Allow HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }


}

#Создание целевой группы Application Load Balancer
#yandex_alb_target_group

resource "yandex_alb_target_group" "bal" {
  name           = "webserver"

  target {
    subnet_id    = yandex_vpc_subnet.diplom_a.id
    ip_address   = yandex_compute_instance.nginx1.network_interface.0.ip_address
  }

  target {
    subnet_id    = yandex_vpc_subnet.diplom_b.id
    ip_address   = yandex_compute_instance.nginx2.network_interface.0.ip_address
  }
}

#Создание бекенд группы 

resource "yandex_alb_backend_group" "webserver-backend-group" {
  name = "bac-web-server"
  session_affinity {
    connection {
      source_ip = true
    }
  }
  http_backend {
    name                   = "bac-web"
    weight                 = 1
    port                   = 80
    target_group_ids       = [yandex_alb_target_group.bal.id]
    load_balancing_config {
      panic_threshold      = 90
    }
    healthcheck {
      timeout              = "10s"
      interval             = "2s"
      healthy_threshold    = 10
      unhealthy_threshold  = 15
      http_healthcheck {  
        path = "/"        #нужный путь (например, "/")
      }
    }
  }
}

#HTTP-роутер для HTTP-трафика

resource "yandex_alb_http_router" "dip-router" {
  name = "my-http-router"
  labels = {
    tf-label    = "tf-label-value"
    empty-label = "s"
  }
}

resource "yandex_alb_virtual_host" "httphost" {
  name           = "httphost"
  http_router_id = yandex_alb_http_router.dip-router.id

  # rate_limit  {
  #   all_requests {
  #     per_second = 1
  #     # или per_minute = <количество_запросов_в_минуту>
  #   }
  #   requests_per_ip  {
  #     per_second = 1
  #     # или per_minute = <количество_запросов_в_минуту>
  #   }
  # }
  
  route {
    name = "httpr"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.webserver-backend-group.id
        timeout          = "60s"
      }
    }
  }
}

  
#   authority             = "<домены>"
#   route_options {
#     security_profile_id = "<идентификатор_профиля_безопасности>"
#   }
# }



# resource "yandex_alb_http_router" "dip-router" {
#   name = "http"
#   labels {
#     tf-label    = "tf-label-value"
#     empty-label = "s"
#   }
#     action {
#       backend_group_id = yandex_alb_backend_group.webserver-backend-group.id
#   }
# }

//
// Create a new Application Load Balancer (ALB)
//
resource "yandex_alb_load_balancer" "my_alb" {
  name = "my-load-balancer"

  network_id = yandex_vpc_network.diplom.id

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.diplom_a.id
    }
  }

  listener {
    name = "my-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.dip-router.id
      }
    }
  }

  log_options {
    discard_rule {
      http_code_intervals = ["HTTP_2XX"]
      discard_percent     = 75
    }
  }
}

# resource "yandex_alb_load_balancer" "alb" {
#   name = "alb"

#   listener {
#     name = "default"
#     port = 80
#     protocol = "HTTP"

#     action {
#       route {
#         http_router_id = yandex_alb_http_router.dip-router.id
#       }
#     }
#   }

#   external_ipv4_address {
#     auto_assign = true
#   }
# }


##### Собираем ip 

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/hosts.ini"
  content = templatefile("${path.module}/hosts.tpl", {
    nginx_ips1 = [yandex_compute_instance.nginx1.network_interface.0.ip_address]
    nginx_ips2 = [yandex_compute_instance.nginx2.network_interface.0.ip_address]
    zb_ips    = [yandex_compute_instance.zabbix.network_interface.0.ip_address]
    lastik_ips    = [yandex_compute_instance.elastik.network_interface.0.ip_address]
    kibana_ips    = [yandex_compute_instance.kibana.network_interface.0.ip_address]
    bastion_ips    = [yandex_compute_instance.bastion.network_interface.0.nat_ip_address]
  })
}