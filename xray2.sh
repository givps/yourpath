#!/bin/bash
# =========================================
# Quick Setup | Script Setup Manager
# Edition : Stable Edition V1.0
# Auther  : givps
# (C) Copyright 2022
# =========================================
red='\e[1;31m'
green='\e[0;32m'
purple='\e[0;35m'
orange='\e[0;33m'
NC='\e[0m'
export Server_URL="raw.githubusercontent.com/givps/yourpath/main"

clear
dateFromServer=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
biji=`date +"%Y-%m-%d" -d "$dateFromServer"`
#########################
MYIP=$(wget -qO- ipv4.icanhazip.com);
MYIP=$(curl -s ipinfo.io/ip )
MYIP=$(curl -sS ipv4.icanhazip.com)
MYIP=$(curl -sS ifconfig.me )
clear
red='\e[1;31m'
green='\e[0;32m'
yell='\e[1;33m'
tyblue='\e[1;36m'
purple='\e[0;35m'
NC='\e[0m'
purple() { echo -e "\\033[35;1m${*}\\033[0m"; }
tyblue() { echo -e "\\033[36;1m${*}\\033[0m"; }
yellow() { echo -e "\\033[33;1m${*}\\033[0m"; }
green() { echo -e "\\033[32;1m${*}\\033[0m"; }
red() { echo -e "\\033[31;1m${*}\\033[0m"; }

red='\e[1;31m'
green='\e[0;32m'
NC='\e[0m'
green() { echo -e "\\033[32;1m${*}\\033[0m"; }
red() { echo -e "\\033[31;1m${*}\\033[0m"; }

echo -e ""
domain=$(cat /root/domain)
sleep 1
echo -e "[ ${green}INFO${NC} ] XRAY Core Installation Begin . . . "
apt update -y
apt upgrade -y
apt install socat -y
apt install curl -y
apt install wget -y
apt install sed -y
apt install nano -y
apt install python3 -y
apt install curl socat xz-utils wget apt-transport-https gnupg gnupg2 gnupg1 dnsutils lsb-release -y 
apt install socat cron bash-completion ntpdate -y
ntpdate pool.ntp.org
apt -y install chrony
timedatectl set-ntp true
systemctl enable chronyd && systemctl restart chronyd
systemctl enable chrony && systemctl restart chrony
timedatectl set-timezone Asia/Kuala_Lumpur
chronyc sourcestats -v
chronyc tracking -v
date
apt install zip -y
apt install curl pwgen openssl netcat cron -y

# Make Folder Log XRAY
mkdir -p /var/log/xray
chmod +x /var/log/xray

# Make Folder XRAY
mkdir -p /usr/local/etc/xray

# Download XRAY Core Latest Link
#latest_version="$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"

# Installation Xray Core
#xraycore_link="https://github.com/givps/Xray-core/releases/download/v$latest_version/xray-linux-64.zip"

# Unzip Xray Linux 64
#cd `mktemp -d`
#curl -sL "$xraycore_link" -o xray.zip
#unzip -q xray.zip && rm -rf xray.zip
#mv xray /usr/local/bin/xray
#chmod +x /usr/local/bin/xray

#Download XRAY Core Dharak
wget -O /usr/local/bin/xray "https://raw.githubusercontent.com/givps/yourpath/main/xray.linux.64bit"
chmod +x /usr/local/bin/xray

# ------------------------------------------
# Colors
# ------------------------------------------
red='\e[1;31m'
green='\e[0;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
nc='\e[0m'

# ------------------------------------------
# Log setup
# ------------------------------------------
LOG_FILE="/var/log/acme-install.log"
mkdir -p /var/log

# Auto log rotation (max 1MB, keep 3 backups)
if [[ -f "$LOG_FILE" ]]; then
    LOG_SIZE=$(stat -c%s "$LOG_FILE")
    if (( LOG_SIZE > 1048576 )); then
        timestamp=$(date +%Y%m%d-%H%M%S)
        mv "$LOG_FILE" "${LOG_FILE}.${timestamp}.bak"
        ls -tp /var/log/acme-install.log.*.bak 2>/dev/null | tail -n +4 | xargs -r rm --
        echo "[$(date)] Log rotated: $LOG_FILE" > "$LOG_FILE"
    fi
fi

# Redirect all output to log
exec > >(tee -a "$LOG_FILE") 2>&1

clear
echo -e "${green}Starting ACME.sh installation with Cloudflare DNS API...${nc}"

# ------------------------------------------
# Check domain
# ------------------------------------------
if [[ ! -f /root/domain ]]; then
    echo -e "${red}[ERROR]${nc} File /root/domain not found!"
    exit 1
fi

domain=$(cat /root/domain)
if [[ -z "$domain" ]]; then
    echo -e "${red}[ERROR]${nc} Domain is empty in /root/domain!"
    exit 1
fi

# ------------------------------------------
# Cloudflare Token (default + manual input)
# ------------------------------------------
DEFAULT_CF_TOKEN="GxfBrA3Ez39MdJo53EV-LiC4dM1-xn5rslR-m5Ru"
echo -e "${blue}Cloudflare API Token Setup:${nc}"
read -rp "Enter Cloudflare API Token (press ENTER to use default token): " CF_Token
if [[ -z "$CF_Token" ]]; then
    CF_Token="$DEFAULT_CF_TOKEN"
    echo -e "${green}[INFO]${nc} Using default Cloudflare API Token."
else
    echo -e "${green}[INFO]${nc} Using manually entered Cloudflare API Token."
fi
export CF_Token

# ------------------------------------------
# Install dependencies
# ------------------------------------------
echo -e "${blue}Installing dependencies...${nc}"
apt update -y >/dev/null 2>&1
command -v curl >/dev/null 2>&1 || apt install -y curl >/dev/null 2>&1
command -v jq >/dev/null 2>&1 || apt install -y jq >/dev/null 2>&1

# ------------------------------------------
# Retry helper
# ------------------------------------------
retry() {
    local MAX_RETRY=5 COUNT=0
    local CMD=("$@")
    until [ $COUNT -ge $MAX_RETRY ]; do
        if "${CMD[@]}"; then
            return 0
        fi
        COUNT=$((COUNT + 1))
        echo -e "${yellow}Command failed. Retry $COUNT/$MAX_RETRY...${nc}"
        sleep 3
    done
    echo -e "${red}Command failed after $MAX_RETRY retries.${nc}"
    exit 1
}

# ------------------------------------------
# Install acme.sh
# ------------------------------------------
ACME_HOME="$HOME/.acme.sh"
cd "$HOME"
if [[ ! -d "$ACME_HOME" ]]; then
    echo -e "${green}Installing acme.sh...${nc}"
    wget -q -O acme.sh https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh
    bash acme.sh --install
    rm -f acme.sh
fi
cd "$ACME_HOME"

# ------------------------------------------
# Install Cloudflare DNS hook
# ------------------------------------------
mkdir -p "$ACME_HOME/dnsapi"
if [[ ! -f "$ACME_HOME/dnsapi/dns_cf.sh" ]]; then
    echo -e "${green}Installing Cloudflare DNS API hook...${nc}"
    wget -O "$ACME_HOME/dnsapi/dns_cf.sh" https://raw.githubusercontent.com/acmesh-official/acme.sh/master/dnsapi/dns_cf.sh
    chmod +x "$ACME_HOME/dnsapi/dns_cf.sh"
fi

# ------------------------------------------
# Register Let's Encrypt account
# ------------------------------------------
echo -e "${green}Registering ACME account with Let's Encrypt...${nc}"
retry bash acme.sh --register-account -m ssl@givps.com --server letsencrypt

# ------------------------------------------
# Issue wildcard certificate
# ------------------------------------------
echo -e "${blue}Issuing wildcard certificate for $domain ...${nc}"
retry bash acme.sh --issue --dns dns_cf -d "$domain" -d "*.$domain" --force --server letsencrypt

# ------------------------------------------
# Install certificate to /etc/xray
# ------------------------------------------
echo -e "${blue}Installing certificate...${nc}"
mkdir -p /etc/xray
retry bash acme.sh --installcert -d "$domain" -d "*.$domain" \
    --fullchainpath /usr/local/etc/xray/xray.crt \
    --keypath /usr/local/etc/xray/xray.key \

# ------------------------------------------
# Cron auto renew + log rotate
# ------------------------------------------
echo -e "${blue}Adding cron job for auto renew...${nc}"
CRON_FILE="/etc/cron.d/acme-renew"
cat > "$CRON_FILE" <<EOF
# Auto renew ACME.sh every 2 months
0 3 1 */2 * root $ACME_HOME/acme.sh --cron --home $ACME_HOME > /var/log/acme-renew.log 2>&1
# Auto log rotation for renew (max 512KB, keep 2 backups)
0 4 1 */2 * root bash -c '
if [[ -f /var/log/acme-renew.log ]]; then
  size=\$(stat -c%s /var/log/acme-renew.log)
  if (( size > 524288 )); then
    ts=\$(date +%Y%m%d-%H%M%S)
    mv /var/log/acme-renew.log /var/log/acme-renew.log.\$ts.bak
    ls -tp /var/log/acme-renew.log.*.bak 2>/dev/null | tail -n +3 | xargs -r rm --
  fi
fi'
EOF

chmod 644 "$CRON_FILE"
systemctl restart cron

echo -e "${green}✅ ACME.sh Cloudflare setup completed successfully.${nc}"
echo -e "Certificate: /usr/local/etc/xray/xray.crt"
echo -e "Key        : /usr/local/etc/xray/xray.key"

# generate certificates
#mkdir /root/.acme.sh
#curl https://raw.githubusercontent.com/givps/yourpath/main/acme.sh -o /root/.acme.sh/acme.sh
#chmod +x /root/.acme.sh/acme.sh
#/root/.acme.sh/acme.sh --upgrade --auto-upgrade
#/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
#/root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
#~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /usr/local/etc/xray/xray.crt --keypath /usr/local/etc/xray/xray.key --ecc
#sleep 1

# Nginx directory file download
mkdir -p /home/vps/public_html

# set uuid
uuid=$(cat /proc/sys/kernel/random/uuid)

# // Installing VMESS-TLS
cat> /usr/local/etc/xray/config.json << END
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
    {
      "port": 1311,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "alterId": 0,
            "level": 0,
            "email": ""
#tls
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings":
            {
              "acceptProxyProtocol": true,
              "path": "/vmess-tls"
            }
      }
    }
  ],
    "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
      "StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true
    }
  }
}
END

# // INSTALLING VMESS NON-TLS
cat> /usr/local/etc/xray/none.json << END
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10085,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api"
    },
    {
     "listen": "127.0.0.1",
     "port": "23456",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "alterId": 0,
            "email": ""
#none
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
	"security": "none",
        "wsSettings": {
          "path": "/vmess-ntls",
          "headers": {
            "Host": ""
          }
         },
        "quicSettings": {},
        "sockopt": {
          "mark": 0,
          "tcpFastOpen": true
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
"outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
      "StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink" : true,
      "statsOutboundDownlink" : true
    }
  }
}
END

# // INSTALLING VLESS-TLS
cat> /usr/local/etc/xray/vless.json << END
{
  "log": {
    "access": "/var/log/xray/access2.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
    {
      "port": 1312,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "level": 0,
            "email": ""
#tls
          }
        ],
        "decryption": "none"
      },
	  "encryption": "none",
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings":
            {
              "acceptProxyProtocol": true,
              "path": "/vless-tls"
            }
      }
    }
  ],
    "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
      "StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true
    }
  }
}
END

# // INSTALLING VLESS NON-TLS
cat> /usr/local/etc/xray/vnone.json << END
{
  "log": {
    "access": "/var/log/xray/access2.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10085,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api"
    },
    {
     "listen": "127.0.0.1",
     "port": "14016",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "level": 0,
            "email": ""
#none
          }
        ],
        "decryption": "none"
      },
      "encryption": "none",
      "streamSettings": {
        "network": "ws",
	"security": "none",
        "wsSettings": {
          "path": "/vless-ntls",
          "headers": {
            "Host": ""
          }
         },
        "quicSettings": {},
        "sockopt": {
          "mark": 0,
          "tcpFastOpen": true
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
"outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
      "StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink" : true,
      "statsOutboundDownlink" : true
    }
  }
}
END

cat> /usr/local/etc/xray/trojanws.json << END
{
  "log": {
    "access": "/var/log/xray/access3.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
    {
      "port": 1313,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "${uuid}",
            "level": 0,
            "email": ""
#tr
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings":
            {
              "acceptProxyProtocol": true,
              "path": "/trojan-tls"
            }
      }
    }
  ],
    "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
      "StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true
    }
  }
}
END

# // INSTALLING TROJAN WS NONE TLS
cat > /usr/local/etc/xray/trnone.json << END
{
"log": {
        "access": "/var/log/xray/access3.log",
        "error": "/var/log/xray/error.log",
        "loglevel": "info"
    },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10085,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api"
    },
    {
      "listen": "127.0.0.1",
      "port": "25432",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "${uuid}",
            "level": 0,
            "email": ""
#trnone
          }
        ],
        "decryption": "none"
      },
            "streamSettings": {
              "network": "ws",
              "security": "none",
              "wsSettings": {
                    "path": "/trojan-ntls",
                    "headers": {
                    "Host": ""
                    }
                }
            }
        }
    ],
"outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
      "StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink" : true,
      "statsOutboundDownlink" : true
    }
  }
}
END

# // INSTALLING TROJAN TCP
cat > /usr/local/etc/xray/trojan.json << END
{
  "log": {
    "access": "/var/log/xray/access4.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
       },
    "inbounds": [
        {
            "port": 1310,
            "listen": "127.0.0.1",
            "protocol": "trojan",
            "settings": {
                "clients": [
                    {
                        "id": "${uuid}",
                        "password": "xxxxx"
#tr
                    }
                ],
                "fallbacks": [
                    {
                        "dest": 80
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "none",
                "tcpSettings": {
                    "acceptProxyProtocol": true
                }
            }
        }
    ],
    "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
      "StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink" : true,
      "statsOutboundDownlink" : true
    }
  }
}
END

# // INSTALLING TROJAN TCP XTLS
cat > /usr/local/etc/xray/xtrojan.json << END
{
    "log": {
        "access": "/var/log/xray/access5.log",
        "error": "/var/log/xray/error.log",
        "loglevel": "info"
  },
  "inbounds": [
    {
      "port": 443,
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "flow": "xtls-rprx-direct",
            "level": 0,
            "email": ""
#trojan-xtls
          }
        ],
        "decryption": "none",
        "fallbacks": [
                    {
                        "dest": 1310,
                        "xver": 1
                    },
                    {
                        "alpn": "h2",
                        "dest": 1318,
                        "xver": 1
                    },
                    {
                        "path": "/vmess-tls",
                        "dest": 1311,
                        "xver": 1
                    },
                    {
                        "path": "/vless-tls",
                        "dest": 1312,
                        "xver": 1
                    },
                    {
                        "path": "/trojan-tls",
                        "dest": 1313,
                        "xver": 1
                    }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "xtls",
        "xtlsSettings": {
          "minVersion": "1.2",
		  "alpn": [
			"http/1.1",
			"h2"
		  ],
          "certificates": [
            {
                    "certificateFile": "/usr/local/etc/xray/xray.crt",
                    "keyFile": "/usr/local/etc/xray/xray.key"
            }
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
END

rm -rf /etc/systemd/system/xray.service.d
rm -rf /etc/systemd/system/xray@.service.d

cat> /etc/systemd/system/xray.service << END
[Unit]
Description=XRAY-Websocket Service
Documentation=https://givps-Project.net https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartSec=3s
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target

END

cat> /etc/systemd/system/xray@.service << END
[Unit]
Description=XRAY-Websocket Service
Documentation=https://givps-Project.net https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/%i.json
Restart=on-failure
RestartSec=3s
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target

END

#nginx config
cat >/etc/nginx/conf.d/xray.conf <<EOF
    server {
             listen 80;
             listen [::]:80;
             listen 8080;
             listen [::]:8080;
             listen 8880;
             listen [::]:8880;	
             server_name 127.0.0.1 localhost;
             ssl_certificate /usr/local/etc/xray/xray.crt;
             ssl_certificate_key /usr/local/etc/xray/xray.key;
             ssl_ciphers EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5;
             ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
             root /usr/share/nginx/html;
        }
EOF
sed -i '$ ilocation /' /etc/nginx/conf.d/xray.conf
sed -i '$ i{' /etc/nginx/conf.d/xray.conf
sed -i '$ iif ($http_upgrade != "Upgrade") {' /etc/nginx/conf.d/xray.conf
sed -i '$ irewrite /(.*) /vless-ntls break;' /etc/nginx/conf.d/xray.conf
sed -i '$ i}' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_redirect off;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_pass http://127.0.0.1:14016;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_http_version 1.1;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header X-Real-IP \$remote_addr;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Upgrade \$http_upgrade;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Connection "upgrade";' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Host \$http_host;' /etc/nginx/conf.d/xray.conf
sed -i '$ i}' /etc/nginx/conf.d/xray.conf

sed -i '$ ilocation = /vmess-ntls' /etc/nginx/conf.d/xray.conf
sed -i '$ i{' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_redirect off;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_pass http://127.0.0.1:23456;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_http_version 1.1;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header X-Real-IP \$remote_addr;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Upgrade \$http_upgrade;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Connection "upgrade";' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Host \$http_host;' /etc/nginx/conf.d/xray.conf
sed -i '$ i}' /etc/nginx/conf.d/xray.conf

sed -i '$ ilocation = /trojan-ntls' /etc/nginx/conf.d/xray.conf
sed -i '$ i{' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_redirect off;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_pass http://127.0.0.1:25432;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_http_version 1.1;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header X-Real-IP \$remote_addr;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Upgrade \$http_upgrade;' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Connection "upgrade";' /etc/nginx/conf.d/xray.conf
sed -i '$ iproxy_set_header Host \$http_host;' /etc/nginx/conf.d/xray.conf
sed -i '$ i}' /etc/nginx/conf.d/xray.conf

sleep 1
echo -e "[ ${orange}SERVICE${NC} ] Restart All service"
systemctl daemon-reload
sleep 1
echo -e "[ ${green}OK${NC} ] Enable & restart xray "

# enable xray vmess ws tls
echo -e "[ ${green}OK${NC} ] Restarting Vmess WS"
systemctl daemon-reload
systemctl enable xray.service
systemctl start xray.service
systemctl restart xray.service

# enable xray vmess ws ntls
systemctl daemon-reload
systemctl enable xray@none.service
systemctl start xray@none.service
systemctl restart xray@none.service

# enable xray vless ws tls
echo -e "[ ${green}OK${NC} ] Restarting Vless WS"
systemctl daemon-reload
systemctl enable xray@vless.service
systemctl start xray@vless.service
systemctl restart xray@vless.service

# enable xray vless ws ntls
systemctl daemon-reload
systemctl enable xray@vnone.service
systemctl start xray@vnone.service
systemctl restart xray@vnone.service

# enable xray trojan ws tls
echo -e "[ ${green}OK${NC} ] Restarting Trojan WS"
systemctl daemon-reload
systemctl enable xray@trojanws.service
systemctl start xray@trojanws.service
systemctl restart xray@trojanws.service

# enable xray trojan ws ntls
systemctl daemon-reload
systemctl enable xray@trnone.service
systemctl start xray@trnone.service
systemctl restart xray@trnone.service

# enable xray trojan xtls
echo -e "[ ${green}OK${NC} ] Restarting Trojan XTLS"
systemctl daemon-reload
systemctl enable xray@xtrojan.service
systemctl start xray@xtrojan.service
systemctl restart xray@xtrojan.service

# enable xray trojan tcp
echo -e "[ ${green}OK${NC} ] Restarting Trojan TCP"
systemctl daemon-reload
systemctl enable xray@trojan.service
systemctl start xray@trojan.service
systemctl restart xray@trojan.service

# enable service multiport
echo -e "[ ${green}OK${NC} ] Restarting Multiport Service"
systemctl enable nginx
systemctl start nginx
systemctl restart nginx

sleep 1

cd /usr/bin
# // VMESS WS FILES
echo -e "[ ${green}INFO${NC} ] Downloading Vmess WS Files"
sleep 1
wget -O add-ws "https://${Server_URL}/add-ws.sh" && chmod +x add-ws
wget -O cek-ws "https://${Server_URL}/cek-ws.sh" && chmod +x cek-ws
wget -O del-ws "https://${Server_URL}/del-ws.sh" && chmod +x del-ws
wget -O renew-ws "https://${Server_URL}/renew-ws.sh" && chmod +x renew-ws
wget -O user-ws "https://${Server_URL}/user-ws.sh" && chmod +x user-ws
wget -O trial-ws "https://${Server_URL}/trial-ws.sh" && chmod +x trial-ws

# // VLESS WS FILES
echo -e "[ ${green}INFO${NC} ] Downloading Vless WS Files"
sleep 1
wget -O add-vless "https://${Server_URL}/add-vless.sh" && chmod +x add-vless
wget -O cek-vless "https://${Server_URL}/cek-vless.sh" && chmod +x cek-vless
wget -O del-vless "https://${Server_URL}/del-vless.sh" && chmod +x del-vless
wget -O renew-vless "https://${Server_URL}/renew-vless.sh" && chmod +x renew-vless
wget -O user-vless "https://${Server_URL}/user-vless.sh" && chmod +x user-vless
wget -O trial-vless "https://${Server_URL}/trial-vless.sh" && chmod +x trial-vless

# // TROJAN WS FILES
echo -e "[ ${green}INFO${NC} ] Downloading Trojan WS Files"
sleep 1
wget -O add-tr "https://${Server_URL}/add-tr.sh" && chmod +x add-tr
wget -O cek-tr "https://${Server_URL}/cek-tr.sh" && chmod +x cek-tr
wget -O del-tr "https://${Server_URL}/del-tr.sh" && chmod +x del-tr
wget -O renew-tr "https://${Server_URL}/renew-tr.sh" && chmod +x renew-tr
wget -O user-tr "https://${Server_URL}/user-tr.sh" && chmod +x user-tr
wget -O trial-tr "https://${Server_URL}/trial-tr.sh" && chmod +x trial-tr

# // TROJAN TCP XTLS
echo -e "[ ${green}INFO${NC} ] Downloading XRAY Vless TCP XTLS Files"
sleep 1
wget -O add-xrt "https://${Server_URL}/add-xrt.sh" && chmod +x add-xrt
wget -O cek-xrt "https://${Server_URL}/cek-xrt.sh" && chmod +x cek-xrt
wget -O del-xrt "https://${Server_URL}/del-xrt.sh" && chmod +x del-xrt
wget -O renew-xrt "https://${Server_URL}/renew-xrt.sh" && chmod +x renew-xrt
wget -O user-xrt "https://${Server_URL}/user-xrt.sh" && chmod +x user-xrt
wget -O trial-xrt "https://${Server_URL}/trial-xrt.sh" && chmod +x trial-xrt

# // TROJAN TCP FILES
echo -e "[ ${green}INFO${NC} ] Downloading Trojan TCP Files"
sleep 1
wget -O add-xtr "https://${Server_URL}/add-xtr.sh" && chmod +x add-xtr
wget -O cek-xtr "https://${Server_URL}/cek-xtr.sh" && chmod +x cek-xtr
wget -O del-xtr "https://${Server_URL}/del-xtr.sh" && chmod +x del-xtr
wget -O renew-xtr "https://${Server_URL}/renew-xtr.sh" && chmod +x renew-xtr
wget -O user-xtr "https://${Server_URL}/user-xtr.sh" && chmod +x user-xtr
wget -O trial-xtr "https://${Server_URL}/trial-xtr.sh" && chmod +x trial-xtr

# // OTHER FILES
echo -e "[ ${green}INFO${NC} ] Downloading Others Files"
sleep 1
