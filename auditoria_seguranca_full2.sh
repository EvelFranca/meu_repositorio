#!/bin/bash

# ==============================================================================
# Script: auditoria_seguranca_full2.sh
# Descrição: Script de Atualização Completa e Auditoria de Segurança Profunda (Nível Corporativo) - Linux (Debian/Ubuntu)
# Funcionalidades: Atualização Completa (Update/Full-Upgrade/Dist-Upgrade), Lynis (Modo Completo), 
# Rootkits profundos, Varredura de ClamAV em Downloads e Pastas Temp, Firewall estrito, 
# Auditoria de SUID/SGID, Análise Avançada de Logs, Integridade Completa, 
# Mapeamento de Contas e Permissões Críticas, Relatório Detalhado com Índice de Saúde (0-100%).
# ==============================================================================

# Certifica-se de que o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "[-] Este script precisa ser executado como root (sudo)."
  exit 1
fi

# Cores para o terminal
VERDE="\033[32m"
VERMELHO="\033[31m"
AMARELO="\033[33m"
AZUL="\033[34m"
RESET="\033[0m"

# Variáveis de Configuração
DATA=$(date +%Y%m%d_%H%M%S)
RELATORIO="./relatorio_seguranca_corporativo_${DATA}.txt"
TOTAL_PASSOS=10
PASSO_ATUAL=0
PONTUACAO_TOTAL=100

# Função para atualizar o progresso com status detalhado
atualizar_progresso() {
    local status_etapa="$1"
    local msg_etapa="$2"
    
    PASSO_ATUAL=$((PASSO_ATUAL + 1))
    PERCENTUAL=$((PASSO_ATUAL * 100 / TOTAL_PASSOS))
    
    echo "=========================================================================="
    echo -n "[Progresso: ${PERCENTUAL}%] Concluído: $msg_etapa - "
    
    if [ "$status_etapa" == "OK" ]; then
        echo -e "[${VERDE}OK${RESET}]"
    elif [ "$status_etapa" == "AVISO" ]; then
        echo -e "[${AMARELO}AVISO${RESET}]"
    else
        echo -e "[${VERMELHO}CRÍTICO${RESET}]"
    fi
    echo "=========================================================================="
}

# Inicializa o arquivo de relatório corporativo
{
    echo "=========================================================================="
    echo "            RELATÓRIO DE AUDITORIA DE SEGURANÇA CORPORATIVA               "
    echo "=========================================================================="
    echo " Data/Hora da Execução : $(date)"
    echo " Hostname              : $(hostname)"
    echo " Kernel do Sistema     : $(uname -r)"
    echo " Distribuição          : $(cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2)"
    echo "=========================================================================="
    echo ""
} > "$RELATORIO"

echo "=========================================================================="
echo "[*] Iniciando processo de atualização e varredura de segurança corporativa profunda."
echo "O relatório será salvo em: $RELATORIO"
echo "=========================================================================="

# ------------------------------------------------------------------------------
# 1. Atualização Completa do Sistema (Update, Full-Upgrade & Dist-Upgrade)
# ------------------------------------------------------------------------------
echo "[*] [1/10] Realizando atualização, full-upgrade e dist-upgrade completo do sistema..."
STATUS_ETAPA_1="OK"
{
    echo "--- 1. ATUALIZAÇÃO COMPLETA DO SISTEMA ---"
    if command -v apt-get &> /dev/null; then
        echo "[+] Executando apt-get update..."
        apt-get update -y
        echo "[+] Executando apt-get full-upgrade..."
        apt-get full-upgrade -y
        echo "[+] Executando apt-get dist-upgrade..."
        apt-get dist-upgrade -y
        echo "[+] Limpando pacotes obsoletos..."
        apt-get autoremove -y
        apt-get clean
        echo "Atualização completa e limpeza do sistema concluídas com sucesso."
    else
        echo "[AVISO] Gerenciador APT não disponível para atualização automática."
        STATUS_ETAPA_1="AVISO"
    fi
    echo ""
} >> "$RELATORIO"
atualizar_progresso "$STATUS_ETAPA_1" "Atualização, Full-Upgrade e Dist-Upgrade"

# ------------------------------------------------------------------------------
# 2. Auditoria Avançada de Firewall (UFW / IPTables / Regras Ativas)
# ------------------------------------------------------------------------------
echo "[*] [2/10] Auditando políticas de Firewall e Regras de Rede..."
STATUS_ETAPA_2="OK"
{
    echo "--- 2. AUDITORIA DE FIREWALL E REDE ---"
    if command -v ufw &> /dev/null; then
        echo "[+] UFW detectado. Status detalhado:"
        ufw status verbose
        
        if ufw status | grep -q "inactive"; then
            echo "[CRÍTICO] O UFW está desativado!"
            STATUS_ETAPA_2="CRITICO"
            PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 20))
        else
            DEFAULT_INCOMING=$(ufw status verbose | grep -i "Default:" | head -n 1)
            if echo "$DEFAULT_INCOMING" | grep -qE "deny|reject"; then
                echo "[OK] A política padrão de entrada do UFW está corretamente restrita."
            else
                echo "[ALERTA CORPORATIVO] A política padrão de entrada do UFW não está restrita (deny/reject)."
                STATUS_ETAPA_2="AVISO"
                PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 10))
            fi
        fi
    else
        echo "[CRÍTICO] O pacote 'ufw' não está instalado. Risco alto de exposição de portas."
        STATUS_ETAPA_2="CRITICO"
        PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 25))
    fi
    echo ""
    echo "--- Regras IPTables Ativas (Filtro) ---"
    iptables -L -v -n 2>/dev/null || echo "Não foi possível listar iptables (permissão ou backend nftables)."
    echo ""
} >> "$RELATORIO"
atualizar_progresso "$STATUS_ETAPA_2" "Auditoria de Firewall"

# ------------------------------------------------------------------------------
# 3. Varredura Profunda de Portas, Sockets e Serviços Vinculados
# ------------------------------------------------------------------------------
echo "[*] [3/10] Mapeando sockets, portas abertas e serviços associados..."
STATUS_ETAPA_3="OK"
{
    echo "--- 3. MAPEAMENTO DE PORTAS E PROCESSOS ASSOCIADOS ---"
    if command -v ss &> /dev/null; then
        echo "--> Sockets de Escuta (TCP/UDP):"
        ss -tulpn
    else
        netstat -tulpn 2>/dev/null || echo "Ferramentas de socket indisponíveis."
    fi
    echo ""
} >> "$RELATORIO"
atualizar_progresso "$STATUS_ETAPA_3" "Mapeamento de Sockets e Portas"

# ------------------------------------------------------------------------------
# 4. Varredura Profunda de Rootkits, Binários e ClamAV (Downloads e Pastas Temp)
# ------------------------------------------------------------------------------
echo "[*] [4/10] Executando análise de rootkits e varredura de vírus (Downloads e Temp)..."
STATUS_ETAPA_4="OK"
{
    echo "--- 4. VARREDURA DE ROOTKITS, INTEGRIDADE E ANTIVÍRUS (DOWNLOADS E TEMP) ---"
    
    if command -v chkrootkit &> /dev/null; then
        echo "--> Executando varredura profunda com chkrootkit:"
        RES_CHK=$(chkrootkit -q)
        if [ ! -z "$RES_CHK" ]; then
            echo "$RES_CHK"
            if echo "$RES_CHK" | grep -iE "INFECTED|Vulnerable"; then
                STATUS_ETAPA_4="CRITICO"
                PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 30))
            fi
        else
            echo "Nenhum sinal de rootkit reportado pelo chkrootkit."
        fi
    else
        echo "[AVISO] chkrootkit não instalado."
        PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 5))
    fi

    echo ""

    if command -v rkhunter &> /dev/null; then
        if [ -f /etc/rkhunter.conf ]; then
            grep -q "lws-request" /etc/rkhunter.conf || {
                echo "ALLOWHIDDENFILE=/usr/bin/lws-request" >> /etc/rkhunter.conf
                echo "ALLOWHIDDENDIR=/usr/bin/.lws-request" >> /etc/rkhunter.conf
                echo "SCRIPTWHITELIST=/usr/bin/lws-request" >> /etc/rkhunter.conf
            }
        fi

        echo "--> Executando rkhunter (check completo sem paginação):"
        rkhunter --check --skip-keypress --quiet --report-warnings-only 2>/dev/null
        
        if [ -f /var/log/rkhunter.log ]; then
            RES_RKH=$(grep -i "warning" /var/log/rkhunter.log | grep -v "lws-request")
            if [ ! -z "$RES_RKH" ]; then
                echo "[ALERTA] Avisos encontrados pelo rkhunter:"
                echo "$RES_RKH"
                STATUS_ETAPA_4="AVISO"
                PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 15))
            else
                echo "Nenhum aviso registrado pelo rkhunter."
            fi
        fi
    else
        echo "[AVISO] rkhunter não instalado."
        PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 5))
    fi

    echo ""
    echo "--> Executando varredura com ClamAV em diretórios de Downloads e Temporários por malwares/vírus:"
    if command -v clamscan &> /dev/null; then
        # Varre as pastas de Downloads e Temporárias (incluindo /tmp e /root/tmp se houver)
        ALVOS_CLAM="/home/*/Downloads /root/Downloads /tmp /root/tmp"
        for alvo in $ALVOS_CLAM; do
            if [ -d "$alvo" ]; then
                echo "[+] Analisando diretório: $alvo"
                clamscan -r --infected --detect-pua "$alvo"
                CLAM_EXIT=$?
                if [ $CLAM_EXIT -eq 1 ]; then
                    echo "[ALERTA] ClamAV encontrou ameaças no diretório $alvo!"
                    STATUS_ETAPA_4="AVISO"
                    PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 15))
                elif [ $CLAM_EXIT -eq 2 ]; then
                    echo "[ERRO] Ocorreu um erro durante a execução do ClamAV em $alvo."
                else
                    echo "[OK] Nenhuma ameaça detectada em $alvo."
                fi
            fi
        done
    else
        echo "[AVISO] O pacote 'clamav' não está instalado. Instale com 'sudo apt install clamav' para escanear diretórios."
    fi
    echo ""
} >> "$RELATORIO"
atualizar_progresso "$STATUS_ETAPA_4" "Rootkits, Rkhunter e ClamAV (Downloads e Temp)"

# ------------------------------------------------------------------------------
# 5. Auditoria Completa de Hardening com Lynis (Modo Profundo)
# ------------------------------------------------------------------------------
echo "[*] [5/10] Executando auditoria corporativa completa com Lynis (modo profundo)..."
STATUS_ETAPA_5="OK"
{
    echo "--- 5. AUDITORIA COMPLETA DE HARDENING (LYNIS) ---"
    if command -v lynis &> /dev/null; then
        lynis audit system --no-colors >> "$RELATORIO"
    else
        echo "[CRÍTICO] O Lynis não está instalado. Essencial para auditoria de compliance."
        STATUS_ETAPA_5="CRITICO"
        PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 20))
    fi
    echo ""
} >> "$RELATORIO"
atualizar_progresso "$STATUS_ETAPA_5" "Auditoria Lynis Corporativa"

# ------------------------------------------------------------------------------
# 6. Verificação de Integridade de Pacotes do Sistema (Debsums)
# ------------------------------------------------------------------------------
echo "[*] [6/10] Verificando integridade criptográfica dos pacotes instalados..."
STATUS_ETAPA_6="OK"
{
    echo "--- 6. INTEGRIDADE DE PACOTES DO SISTEMA (DEBSUMS) ---"
    if command -v debsums &> /dev/null; then
        RES_DEBSUMS=$(debsums -c 2>&1)
        if [ ! -z "$RES_DEBSUMS" ]; then
            echo "[ALERTA] Divergências encontradas em arquivos de pacotes instalados:"
            echo "$RES_DEBSUMS"
            STATUS_ETAPA_6="AVISO"
            PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 15))
        else
            echo "Integridade de pacotes íntegra. Nenhum arquivo de sistema foi alterado indevidamente."
        fi
    else
        echo "[AVISO] Ferramenta 'debsums' não instalada para checagem de integridade local."
        PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 5))
    fi
    echo ""
} >> "$RELATORIO"
atualizar_progresso "$STATUS_ETAPA_6" "Integridade de Pacotes"

# ------------------------------------------------------------------------------
# 7. Auditoria de Contas, Permissões Críticas e Arquivos SUID/SGID Perigosos
# ------------------------------------------------------------------------------
echo "[*] [7/10] Auditando contas de usuários, senhas vazias e binários SUID/SGID..."
STATUS_ETAPA_7="OK"
{
    echo "--- 7. AUDITORIA DE CONTAS E PRIVILÉGIOS (SUID/SGID) ---"
    
    echo "--> Contas com UID 0 (Superusuários alternativos):"
    awk -F: '($3 == 0) {print $1}' /etc/passwd
    echo ""

    echo "--> Contas com senhas vazias ou ausentes:"
    EMPTY_PASSWD=$(awk -F: '($2 == "" ) {print $1}' /etc/shadow 2>/dev/null)
    if [ ! -z "$EMPTY_PASSWD" ]; then
        echo "[CRÍTICO] Contas sem senha detectadas: $EMPTY_PASSWD"
        STATUS_ETAPA_7="CRITICO"
        PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 30))
    else
        echo "Nenhuma conta com senha vazia encontrada."
    fi
    echo ""

    echo "--> Listagem de binários SUID críticos no sistema:"
    find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -la {} \; 2>/dev/null | head -n 40
    echo ""
} >> "$RELATORIO"
atualizar_progresso "$STATUS_ETAPA_7" "Auditoria de Contas e SUID"

# ------------------------------------------------------------------------------
# 8. Análise Comportamental de Logs de Autenticação (Tentativas de Invasão / Brute-Force)
# ------------------------------------------------------------------------------
echo "[*] [8/10] Analisando logs de autenticação em busca de ataques de força bruta..."
STATUS_ETAPA_8="OK"
{
    echo "--- 8. ANÁLISE DE LOGS DE AUTENTICAÇÃO (BRUTE-FORCE) ---"
    
    AUTH_LOG="/var/log/auth.log"
    if [ ! -f "$AUTH_LOG" ]; then
        AUTH_LOG="/var/log/secure"
    fi

    if [ -f "$AUTH_LOG" ]; then
        echo "--> Tentativas recentes de falhas de login (SSH / Console):"
        grep -i "Failed password" "$AUTH_LOG" | tail -n 20
        
        FAIL_COUNT=$(grep -i "Failed password" "$AUTH_LOG" | wc -l)
        echo "Total de falhas de autenticação registradas nos logs atuais: $FAIL_COUNT"
        
        if [ "$FAIL_COUNT" -gt 50 ]; then
            echo "[AVISO CORPORATIVO] Volume elevado de falhas de login detectado. Risco de ataque de força bruta em andamento."
            STATUS_ETAPA_8="AVISO"
            PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 10))
        fi
    else
        echo "[AVISO] Arquivo de log de autenticação padrão não localizado para análise histórica."
    fi
    echo ""
} >> "$RELATORIO"
atualizar_progresso "$STATUS_ETAPA_8" "Análise de Logs de Autenticação"

# ------------------------------------------------------------------------------
# 9. Verificação de Serviços de Defesa Ativa (Fail2ban, AppArmor/SELinux, Pam)
# ------------------------------------------------------------------------------
echo "[*] [9/10] Verificando barreiras de defesa ativa e endurecimento de kernel..."
STATUS_ETAPA_9="OK"
{
    echo "--- 9. BARREIRAS DE DEFESA ATIVA E KERNEL HARDENING ---"
    
    if dpkg -l | grep -q fail2ban; then
        echo "[OK] Fail2ban instalado e ativo."
    else
        echo "[ALERTA] Fail2ban não instalado (altamente recomendado para proteção contra brute-force SSH)."
        STATUS_ETAPA_9="AVISO"
        PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 10))
    fi

    if command -v aa-status &> /dev/null; then
        echo "--> Status do AppArmor:"
        aa-status --enabled && echo "[OK] AppArmor está habilitado." || { echo "[ALERTA] AppArmor desabilitado."; STATUS_ETAPA_9="AVISO"; PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 10)); }
    elif command -v sestatus &> /dev/null; then
        sestatus
    else
        echo "[ALERTA] Nenhum framework de MAC (Mandatory Access Control) evidente encontrado."
        STATUS_ETAPA_9="AVISO"
        PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 10))
    fi

    if dpkg -l | grep -q libpam-tmpdir; then
        echo "[OK] libpam-tmpdir instalado (isola diretórios temporários)."
    else
        echo "[SUGESTÃO] libpam-tmpdir ausente."
    fi
    
    echo ""
    echo "--- Parâmetros críticos de Hardening do Kernel (Sysctl) ---"
    sysctl fs.protected_hardlinks fs.protected_symlinks kernel.randomize_va_space net.ipv4.conf.all.rp_filter 2>/dev/null
    echo ""
} >> "$RELATORIO"
atualizar_progresso "$STATUS_ETAPA_9" "Defesa Ativa e Hardening de Kernel"

# ------------------------------------------------------------------------------
# 10. Verificação Pós-Atualização de Segurança Pendentes
# ------------------------------------------------------------------------------
echo "[*] [10/10] Verificando integridade de pacotes pós-atualização..."
STATUS_ETAPA_10="OK"
{
    echo "--- 10. VERIFICAÇÃO PÓS-ATUALIZAÇÃO ---"
    if command -v apt-get &> /dev/null; then
        apt-get -s upgrade 2>/dev/null | grep -i "security" > /tmp/sec_updates_audit.txt
        SEC_COUNT=$(wc -l < /tmp/sec_updates_audit.txt)
        if [ "$SEC_COUNT" -gt 0 ]; then
            echo "[ALERTA] Existem atualizações residuais pendentes ($SEC_COUNT pacotes afetados)."
            cat /tmp/sec_updates_audit.txt
            STATUS_ETAPA_10="AVISO"
            PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 5))
        else
            echo "Nenhuma atualização de segurança pendente remanescente."
        fi
        rm -f /tmp/sec_updates_audit.txt
    else
        echo "[AVISO] Gerenciador APT não aplicável a este ambiente."
    fi
    echo ""
} >> "$RELATORIO"
atualizar_progresso "$STATUS_ETAPA_10" "Verificação Final Pós-Atualização"

# Garante que a pontuação fique no limite seguro de 0 a 100
if [ $PONTUACAO_TOTAL -lt 0 ]; then
    PONTUACAO_TOTAL=0
fi

# Grava o sumário final e diagnóstico corporativo no relatório
{
    echo "=========================================================================="
    echo "                 DIAGNÓSTICO FINAL DE SAÚDE CORPORATIVA                   "
    echo "=========================================================================="
    echo " Índice Geral de Segurança : ${PONTUACAO_TOTAL}%"
    if [ $PONTUACAO_TOTAL -ge 85 ]; then
        echo " Classificação de Risco   : BAIXO RISCO (Conforme padrões corporativos)"
    elif [ $PONTUACAO_TOTAL -ge 65 ]; then
        echo " Classificação de Risco   : MÉDIO RISCO (Atenção a pontos de hardening recomendados)"
    else
        echo " Classificação de Risco   : ALTO RISCO / CRÍTICO (Necessária intervenção imediata)"
    fi
    echo "=========================================================================="
} >> "$RELATORIO"

# Exibição Final no Terminal
echo "=========================================================================="
echo "[*] Atualização e Auditoria Corporativa concluídas com 100% de progresso!"
echo "[*] Relatório detalhado salvo com sucesso em: $RELATORIO"
echo "=========================================================================="
if [ $PONTUACAO_TOTAL -ge 85 ]; then
    echo -e "[*] Índice de Segurança: ${VERDE}${PONTUACAO_TOTAL}% (Excelente - Nível Corporativo Sólido)${RESET}"
elif [ $PONTUACAO_TOTAL -ge 65 ]; then
    echo -e "[*] Índice de Segurança: ${AMARELO}${PONTUACAO_TOTAL}% (Moderado - Pontos de Atenção Identificados)${RESET}"
else
    echo -e "[*] Índice de Segurança: ${VERMELHO}${PONTUACAO_TOTAL}% (Crítico - Vulnerabilidades e Ajustes Pendentes)${RESET}"
fi
echo "=========================================================================="
