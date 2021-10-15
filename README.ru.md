# docker formula

Формула для установки и настройки `docker` а так же `docker-compose`.

## Доступные стейты

* [docker](#docker)
* [docker.repo](#docker.repo)
* [docker.server](#docker.server)
* [docker.server.config](#docker.server.config)
* [docker.server.tls](#docker.server.tls)
* [docker.server.service](#docker.server.service)
* [docker.server.software.binary](#docker.server.software.binary)
* [docker.server.software.package](#docker.server.software.package)
* [docker.server.software.pip](#docker.server.software.pip)
* [docker.compose](#docker.compose)
* [docker.compose.software](#docker.compose.software)
* [docker.compose.shell_completion](#docker.compose.shell_completion)
* [docker.volumes](#docker.volumes)
* [docker.networks](#docker.networks)
* [docker.images](#docker.images)
* [docker.containers](#docker.containers)

### docker

Мета стейт - выполнит все остальные стейты.

### docker.repo

Стейт для настройки официального репозиторя Docker. Официально поддерживаются следующие ОС: Debian, Ubuntu, CentOS, Fedora. Пакеты вероятно будут корректно работать на деривативах поддерживаемых ОС, но гарантий этого нет.

В зависимости от значения параметра `docker.server.use_upstream` будут выполненые разные операции:

* `repo`, `package` - в систему будет добавлено новый репозиторий
* `binary` - репозиторий будет удален из системы

### docker.server

Места стейт - выполнит все необходимые стейты для запуска `docker` серера. В зависимости от указанного в пилларах `docker.server.use_upstream` метода установки будет выполнена установка из пакетов или с использованием готовых статически скомилированных бинарных файлов.

* `repo`, `package` - установка из пакетов, выполенение стейта `docker.server.software.package`
* `binary` - установка с использованием готовых статически скомилированных бинарных файлов, выполнение стейта `docker.server.software.binary`, _данный метод установки пока что не реализован_.

### docker.server.config

Стейт отвечающий за генерацию конфигурационного файла docker сервера, по умолчанию `/etc/docker/daemon.json` на основе данных из пилларов.

### docker.server.tls

Набор стейтов для управления TLS сертификатами для docker демона. Официальная [документация](https://docs.docker.com/engine/security/protect-access/#use-tls-https-to-protect-the-docker-daemon-socket) по защите TCP сокета с помощью TLS (=HTTPS).

* key - создание приватного ключа
* cert - создание сертификата
* cacert - установка CA сертификата
* packages - установка пакетов, необходимых для генерации самоподписного сертификата

Docker демон поддерживает два режима работы TLS:

* С проверкой сертификата клиента - в этом режиме требуется указать следующие параметры `tlsverify`, `tlscacert`, `tlscert`, `tlskey`
* Без проверки сертификата клиента - в этом режиме нужны лишь `tls`, `tlscert`, `tlskey`

Минимально необходимая конфигурация для включения HTTPS сокета с использованием самоподписного сертификата.

```yaml
docker:
  server:
    config:
      data:
        tls: true
        tlskey: /etc/docker/tls/server-key.pem
        tlscert: /etc/docker/tls/server-cert.pem
        hosts:
          - fd://
          - tcp://0.0.0.0:2376
    tls:
      key:
        params:
          bits: 2048
      cert:
        params:
          days_valid: 3650
          # use minion id as a Common Name
          CN: {{ grains.id }}
          subjectAltName: "DNS:{{ grains.id }},IP:127.0.0.1"
```

Конфигурация с проверкой клиентского сертификата, используются символические ссылки на готовые сертификаты расположенные на миньоне (они предвариательно выпущены с помощью `pki` формулы), в качестве CA сертификата используется системная цепочка CA сертификатов (указан путь для Debian систем).

```yaml
docker:
  server:
    config:
      data:
        tlsverify: false
        tlscacert: /etc/docker/tls/ca.pem
        tlskey: /etc/docker/tls/server-key.pem
        tlscert: /etc/docker/tls/server-cert.pem
        hosts:
          - fd://
          - tcp://0.0.0.0:2376
    tls:
      key:
        symlink: true
        source: /etc/pki/api/docker-server.key
      cert:
        symlink: true
        source: /etc/pki/api/docker-server.crt
      cacert:
        symlink: true
        source: /etc/ssl/certs/ca-certificates.crt
```

### docker.server.service

Стейт отвечающий за настройку и запуск сервиса docker.

### docker.server.software.binary

Данный метод установки пока что не реализован.

### docker.server.software.package

Мета стейт для установки docker сервера из пакетов (deb, rpm). При запуске этого стейта будут выполнены следующие шаги:

* подключен репозиторий
* установлены вспомогаетльные пакеты (зависимости) необходимые для работы самого docker и для взаимодействия Salt с docker демоном.
* установлены основные пакеты docker сервера
* при необходимости будут установлены `pip` пакеты
* выполнена настройка docker сервера
* выполнена конфигурация сервиса docker - сервис будет запущен и настроен для старта после загрузки ОС (описано поведение по умолчанию, его можно изменить изменив параметры `docker.server.service`)

### docker.server.software.pip

Стейт для установки `pip` пакетов. Предварительно будет установлена сама `pip` утилита.

### docker.compose

Мета стейт для запуска всех стейтов связанных с `docker-compose`.

### docker.compose.software

Стейт отвечающий за установку `docker-compose`.

### docker.compose.shell_completion

Стейт отвечающий за установку автодополнения в командной строке при работе с `docker-compose`. <https://docs.docker.com/compose/completion/>. На данный момент поддерживается только `bash`.

### docker.volumes

Стейт для управления `docker volumes`

### docker.networks

Стейт для управления `docker networks`

### docker.images

Стейт для управления `docker images`

### docker.containers

Стейт для управления контейнерами docker.

## Известные проблемы

В CentOS, для взаимодействия между Salt и docker требуется перезапуск `salt-minon`, без перезапуска salt не может обнаружить Python библиотеку docker (docker-py).

Таким образому, необходимо сначала установить docker сервер с помощью стейта `docker.server`, затем перезапустить minion ([различные методы перезапуска](https://docs.saltproject.io/en/latest/faq.html#what-is-the-best-way-to-restart-a-salt-minion-daemon-using-salt-after-upgrade)), например с помощью команды

```bash
salt minion-id cmd.run 'salt-call --local service.restart salt-minion'
```

после этого можно запускать стейты для работы с Docker, такие как `docker.volumes`, `docker.networks`, `docker.containers`.

## TODO

* Управление `docker-compose` проектами
* Docker Swarm
