# Solar - Puma systemd

## Ubuntu

### Localização do script

    /var/www/html/solar/shared/config/scripts/solar.socket
    /var/www/html/solar/shared/config/scripts/solar.service

### Criando um link no /etc/systemd/system para o script

    sudo ln -s /var/www/html/solar/shared/config/scripts/solar.socket /etc/systemd/system/solar.socket
    sudo ln -s /var/www/html/solar/shared/config/scripts/solar.service /etc/systemd/system/solar.service

### Comandos para habilitar e rodar serviço

#### Depois da instalação do serviço ou em caso de qualquer mudança

    sudo systemctl daemon-reload

#### Habilitar para iniciar com o boot

    sudo systemctl enable solar.socket solar.service

#### Inicar

    sudo systemctl start solar.socket solar.service

#### Checar status

    sudo systemctl status solar.socket solar.service

#### Restart

    sudo systemctl restart solar.socket solar.service
