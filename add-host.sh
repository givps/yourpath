#!/bin/bash
# =========================================
# Quick Setup | Script Setup Manager
# Edition : Stable Edition V1.0
# Auther  : NevermoreSSH
# (C) Copyright 2022
# =========================================
clear
red='\e[1;31m'
green='\e[0;32m'
purple='\e[0;35m'
orange='\e[0;33m'
NC='\e[0m'
rm -f /var/lib/crot-script/ipvps.conf
rm -f /var/lib/premium-script/ipvps.conf
rm -f /usr/local/etc/xray/domain
#echo -e "${red}♦️${NC} ${green}Established By NevermoreSSH 2022${NC} ${red}♦️${NC}"
#DOWNLOAD SOURCE SCRIPT
echo -e "${red}    ♦️${NC} ${green} CUSTOM SETUP DOMAIN VPS     ${NC}"
echo -e "${red}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m${NC}"
echo "1. Use Domain From Script / Gunakan Domain Dari Script"
echo "2. Choose Your Own Domain / Pilih Domain Sendiri"
echo -e "${red}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m${NC}"
read -rp "Choose Your Domain Installation : " dom 

if test $dom -eq 1; then
clear
rm -f cf.sh
wget -q -O /root/cf.sh "https://${Server_URL}/cf.sh"
chmod +x /root/cf.sh
./cf.sh
elif test $dom -eq 2; then
read -rp "Enter Your Domain : " domen 
echo $domen > /root/domain
echo "IP=$dom" > /var/lib/crot-script/ipvps.conf
echo "IP=$dom" > /var/lib/premium-script/ipvps.conf
echo "$dom" > /usr/local/etc/xray/domain
else 
echo "Wrong Argument"
exit 1
fi
#echo -e "${GREEN}Done!${NC}"
###
#echo -e "Please Insert  Your Domain"
#read -p "Hostname / Domain: " host
#echo "IP=$host" >> /var/lib/crot-script/ipvps.conf
#echo "IP=$host" >> /var/lib/premium-script/ipvps.conf
#echo "$host" > /usr/local/etc/xray/domain
#clear
#echo -e "Renew Certificate Started . . . ."
#echo start
#sleep 1
#source /var/lib/premium-script/ipvps.conf
#domain=$(cat /usr/local/etc/xray/domain)
systemctl stop nginx
systemctl stop xray.service
systemctl stop xray@none.service
systemctl stop xray@vless.service
systemctl stop xray@vnone.service
systemctl stop xray@trojan.service
systemctl stop xray@trnone.service
systemctl stop xray@xtrojan.service
systemctl stop xray@trojan.service

# ------------------------------------------
# Colors
# ------------------------------------------
red='\e[1;31m'
green='\e[0;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
nc='\e[0m'

#delete old
rm -f /usr/local/etc/xray/xray.crt
rm -f /usr/local/etc/xray/xray.key

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
if [[ ! -f /usr/local/etc/xray/domain ]]; then
    echo -e "${red}[ERROR]${nc} File /usr/local/etc/xray/domain not found!"
    exit 1
fi

domain=$(cat /usr/local/etc/xray/domain)
if [[ -z "$domain" ]]; then
    echo -e "${red}[ERROR]${nc} Domain is empty in /usr/local/etc/xray/domain!"
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
retry bash acme.sh --installcert -d "$domain" \
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

#echo -e "[ ${green}INFO${NC} ] Starting renew cert... "
#rm -r /root/.acme.sh
#sleep 1
#mkdir /root/.acme.sh
#curl https://raw.githubusercontent.com/NevermoreSSH/yourpath/main/acme.sh -o /root/.acme.sh/acme.sh
#chmod +x /root/.acme.sh/acme.sh
#/root/.acme.sh/acme.sh --upgrade --auto-upgrade
#/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
#/root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
#~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /usr/local/etc/xray/xray.crt --keypath /usr/local/etc/xray/xray.key --ecc
echo -e "[ ${green}INFO${NC} ] Restart All Service" 
sleep 1
systemctl restart nginx
systemctl restart xray.service
systemctl restart xray@none.service
systemctl restart xray@vless.service
systemctl restart xray@vnone.service
systemctl restart xray@trojanws.service
systemctl restart xray@trnone.service
systemctl restart xray@xtrojan.service
systemctl restart xray@trojan.service
echo -e "[ ${green}INFO${NC} ] All finished !" 
sleep 1
clear
