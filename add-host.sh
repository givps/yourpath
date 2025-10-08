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
export Server_URL="raw.githubusercontent.com/givps/yourpath/main"
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

systemctl stop nginx
systemctl stop xray.service
systemctl stop xray@none.service
systemctl stop xray@vless.service
systemctl stop xray@vnone.service
systemctl stop xray@trojan.service
systemctl stop xray@trnone.service
systemctl stop xray@xtrojan.service
systemctl stop xray@trojan.service
# Color setup
red='\e[1;31m'; green='\e[0;32m'; yellow='\e[1;33m'; blue='\e[1;34m'; nc='\e[0m'

# Log setup
LOG_FILE="/var/log/acme-install.log"
mkdir -p /var/log
[ -f "$LOG_FILE" ] && [ "$(stat -c%s "$LOG_FILE")" -gt 1048576 ] && {
  ts=$(date +%Y%m%d-%H%M%S)
  mv "$LOG_FILE" "$LOG_FILE.$ts.bak"
  ls -tp /var/log/acme-install.log.*.bak 2>/dev/null | tail -n +4 | xargs -r rm --
}
exec > >(tee -a "$LOG_FILE") 2>&1

# Clean old certs
rm -f /usr/local/etc/xray/{xray.crt,xray.key}
clear; echo -e "${green}Starting ACME.sh setup...${nc}"

# Domain check
domain=$(cat /usr/local/etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null)
[[ -z "$domain" ]] && echo -e "${red}[ERROR] Domain file not found or empty!${nc}" && exit 1

# Cloudflare token
DEFAULT_CF_TOKEN="GxfBrA3Ez39MdJo53EV-LiC4dM1-xn5rslR-m5Ru"
read -rp "Enter Cloudflare API Token (ENTER for default): " CF_Token
export CF_Token="${CF_Token:-$DEFAULT_CF_TOKEN}"

# Dependencies
echo -e "${blue}Installing dependencies...${nc}"
apt update -y >/dev/null 2>&1
apt install -y curl jq wget cron >/dev/null 2>&1

# Retry helper
retry() { local n=1; until "$@"; do ((n++==5)) && exit 1; echo -e "${yellow}Retry $n...${nc}"; sleep 3; done; }

# Install acme.sh
ACME_HOME="$HOME/.acme.sh"
[ ! -d "$ACME_HOME" ] && {
  echo -e "${green}Installing acme.sh...${nc}"
  wget -qO - https://raw.githubusercontent.com/givps/yourpath/main/acme.sh | bash
}

# Ensure Cloudflare hook exists
mkdir -p "$ACME_HOME/dnsapi"
[ ! -f "$ACME_HOME/dnsapi/dns_cf.sh" ] && wget -qO "$ACME_HOME/dnsapi/dns_cf.sh" https://raw.githubusercontent.com/acmesh-official/acme.sh/master/dnsapi/dns_cf.sh && chmod +x "$ACME_HOME/dnsapi/dns_cf.sh"

# Register account
echo -e "${green}Registering ACME account...${nc}"
retry bash "$ACME_HOME/acme.sh" --register-account -m ssl@givps.com --server letsencrypt

# Issue certificate
echo -e "${blue}Issuing wildcard certificate for ${domain}...${nc}"
retry bash "$ACME_HOME/acme.sh" --issue --dns dns_cf -d "$domain" -d "*.$domain" --force --server letsencrypt

# Install certs
echo -e "${blue}Installing certificate...${nc}"
mkdir -p /etc/xray
retry bash "$ACME_HOME/acme.sh" --installcert -d "$domain" \
  --fullchainpath /usr/local/etc/xray/xray.crt \
  --keypath /usr/local/etc/xray/xray.key

# Auto renew cron
cat > /etc/cron.d/acme-renew <<EOF
0 3 1 */2 * root $ACME_HOME/acme.sh --cron --home $ACME_HOME > /var/log/acme-renew.log 2>&1
EOF
chmod 644 /etc/cron.d/acme-renew
systemctl restart cron

echo -e "${green}✅ ACME.sh + Cloudflare DNS setup completed.${nc}"
echo -e "CRT: /usr/local/etc/xray/xray.crt"
echo -e "KEY: /usr/local/etc/xray/xray.key"

elif test $dom -eq 2; then
read -rp "Enter Your Domain : " domen 
echo $domen > /root/domain
echo "IP=$dom" > /var/lib/crot-script/ipvps.conf
echo "IP=$dom" > /var/lib/premium-script/ipvps.conf
echo "$dom" > /usr/local/etc/xray/domain
systemctl stop nginx
systemctl stop xray.service
systemctl stop xray@none.service
systemctl stop xray@vless.service
systemctl stop xray@vnone.service
systemctl stop xray@trojan.service
systemctl stop xray@trnone.service
systemctl stop xray@xtrojan.service
systemctl stop xray@trojan.service
# Color setup
red='\e[1;31m'; green='\e[0;32m'; yellow='\e[1;33m'; blue='\e[1;34m'; nc='\e[0m'

# Log setup
LOG_FILE="/var/log/acme-install.log"
mkdir -p /var/log
[ -f "$LOG_FILE" ] && [ "$(stat -c%s "$LOG_FILE")" -gt 1048576 ] && {
  ts=$(date +%Y%m%d-%H%M%S)
  mv "$LOG_FILE" "$LOG_FILE.$ts.bak"
  ls -tp /var/log/acme-install.log.*.bak 2>/dev/null | tail -n +4 | xargs -r rm --
}
exec > >(tee -a "$LOG_FILE") 2>&1

# Clean old certs
rm -f /usr/local/etc/xray/{xray.crt,xray.key}
clear; echo -e "${green}Starting ACME.sh setup...${nc}"

# Domain check
domain=$(cat /usr/local/etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null)
[[ -z "$domain" ]] && echo -e "${red}[ERROR] Domain file not found or empty!${nc}" && exit 1

# Cloudflare token
DEFAULT_CF_TOKEN="GxfBrA3Ez39MdJo53EV-LiC4dM1-xn5rslR-m5Ru"
read -rp "Enter Cloudflare API Token (ENTER for default): " CF_Token
export CF_Token="${CF_Token:-$DEFAULT_CF_TOKEN}"

# Dependencies
echo -e "${blue}Installing dependencies...${nc}"
apt update -y >/dev/null 2>&1
apt install -y curl jq wget cron >/dev/null 2>&1

# Retry helper
retry() { local n=1; until "$@"; do ((n++==5)) && exit 1; echo -e "${yellow}Retry $n...${nc}"; sleep 3; done; }

# Install acme.sh
ACME_HOME="$HOME/.acme.sh"
[ ! -d "$ACME_HOME" ] && {
  echo -e "${green}Installing acme.sh...${nc}"
  wget -qO - https://raw.githubusercontent.com/givps/yourpath/main/acme.sh | bash
}

# Ensure Cloudflare hook exists
mkdir -p "$ACME_HOME/dnsapi"
[ ! -f "$ACME_HOME/dnsapi/dns_cf.sh" ] && wget -qO "$ACME_HOME/dnsapi/dns_cf.sh" https://raw.githubusercontent.com/acmesh-official/acme.sh/master/dnsapi/dns_cf.sh && chmod +x "$ACME_HOME/dnsapi/dns_cf.sh"

# Register account
echo -e "${green}Registering ACME account...${nc}"
retry bash "$ACME_HOME/acme.sh" --register-account -m ssl@givps.com --server letsencrypt

# Issue certificate
echo -e "${blue}Issuing wildcard certificate for ${domain}...${nc}"
retry bash "$ACME_HOME/acme.sh" --issue --dns dns_cf -d "$domain" -d "*.$domain" --force --server letsencrypt

# Install certs
echo -e "${blue}Installing certificate...${nc}"
mkdir -p /etc/xray
retry bash "$ACME_HOME/acme.sh" --installcert -d "$domain" \
  --fullchainpath /usr/local/etc/xray/xray.crt \
  --keypath /usr/local/etc/xray/xray.key

# Auto renew cron
cat > /etc/cron.d/acme-renew <<EOF
0 3 1 */2 * root $ACME_HOME/acme.sh --cron --home $ACME_HOME > /var/log/acme-renew.log 2>&1
EOF
chmod 644 /etc/cron.d/acme-renew
systemctl restart cron

echo -e "${green}✅ ACME.sh + Cloudflare DNS setup completed.${nc}"
echo -e "CRT: /usr/local/etc/xray/xray.crt"
echo -e "KEY: /usr/local/etc/xray/xray.key"
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
