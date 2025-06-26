#!/usr/bin/env bash
set -eux

# Автоматическое получение последней версии Proxmox VE
if [ -z "${PROXMOX_VERSION:-}" ]; then
    echo "Получение информации о последней версии Proxmox VE..."
    PROXMOX_VERSION=$(curl -s https://enterprise.proxmox.com/iso/ | grep -oP 'proxmox-ve_\K[0-9]+\.[0-9]+-[0-9]+' | sort -V | tail -1)
    echo "Найдена версия: ${PROXMOX_VERSION}"
fi

# Если SHA не указан, скачиваем без проверки (не рекомендуется для продакшена)
PROXMOX_ISO_SHA=${PROXMOX_ISO_SHA:-}

mkdir -p answers dist
cd dist

if ! [ -f "dist/proxmox-ve_${PROXMOX_VERSION}.iso" ]; then
    aria2c https://enterprise.proxmox.com/iso/proxmox-ve_${PROXMOX_VERSION}.iso
    if [ -n "${PROXMOX_ISO_SHA}" ]; then
        echo "${PROXMOX_ISO_SHA}  proxmox-ve_${PROXMOX_VERSION}.iso" | sha256sum --status -c -
    else
        echo "Предупреждение: SHA256 не указан, пропускаем проверку целостности"
    fi
fi
cd ..

find answers -maxdepth 1 -name '*.toml' | while read -r fname
do
    fname=$(basename "${fname}")
    host="${fname%.*}"
    
    echo -e "Host ${host}\t\t Start =============================="
    proxmox-auto-install-assistant prepare-iso dist/proxmox-ve_${PROXMOX_VERSION}.iso \
        --fetch-from iso --answer-file "answers/${host}.toml" \
        --output "dist/proxmox-ve_${PROXMOX_VERSION}_auto_${host}.iso"
    echo -e "Host ${host}\t\t End ================================"
done
