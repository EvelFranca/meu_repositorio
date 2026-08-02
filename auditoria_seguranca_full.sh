#!/bin/bash

# ==============================================================================
# Script: auditoria_seguranca_full.sh
# Descrição: Script de Auditoria de Segurança - Linux (Debian/Ubuntu)
# Funcionalidades: Lynis, Rootkits, Firewall, Portas, Pacotes Adicionais, 
# Relatório na Pasta Atual, Status Simples e Cálculo de Saúde do Sistema (0-100%)
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
RESET="\033[0m"

# Variáveis de Configuração (Salva o relatório na mesma pasta de execução)
DATA=$(date +%Y%m%d_%H%M%S)
RELATORIO="./relatorio_seguranca_${DATA}.txt"
TOTAL_PASSOS=6
PASSO_ATUAL=0

# Contadores de pontuação para o cálculo final (Inicia com 100 pontos)
PONTUACAO_TOTAL=100

# Função para atualizar o progresso com status simples
atualizar_progresso() {
    local status_etapa="$1"
    local msg_etapa="$2"
    
    PASSO_ATUAL=$((PASSO_ATUAL + 1))
    PERCENTUAL=$((PASSO_ATUAL * 100 / TOTAL_PASSOS))
    
    echo "========================================================"
    echo -n "[Progresso: ${PERCENTUAL}%] Concluído: $msg_etapa - "
    
    if [ "$status_etapa" == "OK" ]; then
        echo -e "[${VERDE}OK${RESET}]"
    else
        echo -e "[${VERMELHO}Atenção${RESET}]"
    fi
    echo "========================================================"
}

# Inicializa o arquivo de relatório
{
    echo "========================================================"
    echo "         RELATÓRIO DE AUDITORIA DE SEGURANÇA           "
    echo " Data/Hora: $(date)"
    echo " Hostname: $(hostname)"
    echo "========================================================"
    echo ""
} > "$RELATORIO"

echo "[*] Iniciando auditoria de segurança. O relatório será salvo em: $RELATORIO"

# ------------------------------------------------------------------------------
# 1. Verificação de Firewall (UFW)
# ------------------------------------------------------------------------------
echo "[*] Verificando status do Firewall (UFW)..."
STATUS_ETAPA_1="OK"
{
    echo "--- STATUS DO FIREWALL (UFW) ---"
    if command -v ufw &> /dev/null; then
        ufw status verbose
        ALERTA_UFW=$(ufw status | grep -i "inactive")
        if [ ! -z "$ALERTA_UFW" ]; then
            echo "[ALERTA] O UFW está inativo! Recomenda-se ativar o firewall."
            STATUS_ETAPA_1="ALERTA"
            PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 15))
        fi
    else
        echo "[ALERTA] O pacote 'ufw' não está instalado."
        STATUS_ETAPA_1="ALERTA"
        PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 20))
    fi
    echo ""
} >> "$RELATORIO"
atualizar_progresso "$STATUS_ETAPA_1" "Verificação do Firewall"

# ------------------------------------------------------------------------------
# 2. Verificação de Portas Abertas e Serviços (`ss`)
# ------------------------------------------------------------------------------
echo "[*] Verificando portas abertas e conexões de rede..."
STATUS_ETAPA_2="OK"
{
    echo "--- PORTAS ABERTAS E CONEXÕES (SOCKETS) ---"
    ss -tuln
    echo ""
} >> "$RELATORIO"
atualizar_progresso "$STATUS_ETAPA_2" "Verificação de Portas e Conexões"

# ------------------------------------------------------------------------------
# 3. Varredura de Rootkits (Chkrootkit e Rkhunter)
# ------------------------------------------------------------------------------
echo "[*] Executando varredura de rootkits (chkrootkit / rkhunter)..."
STATUS_ETAPA_3="OK"
{
    echo "--- VERIFICAÇÃO DE ROOTKITS ---"
    
    if command -v chkrootkit &> /dev/null; then
        echo "--> Executando chkrootkit:"
        RESULT_CHK=$(chkrootkit | grep -E "INFECTED|Vulnerable|warning")
        if [ ! -z "$RESULT_CHK" ]; then
            echo "$RESULT_CHK"
            STATUS_ETAPA_3="ALERTA"
            PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 30))
        else
            echo "Nenhuma ameaça óbvia detectada pelo chkrootkit."
        fi
    else
        echo "[AVISO] chkrootkit não está instalado."
        PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 5))
    fi

    echo ""

    if command -v rkhunter &> /dev/null; then
        echo "--> Executando rkhunter (modo check):"
        rkhunter --check --silent --sk
        if [ -f /var/log/rkhunter.log ]; then
            RESULT_RKH=$(grep -i "warning" /var/log/rkhunter.log)
            if [ ! -z "$RESULT_RKH" ]; then
                echo "$RESULT_RKH"
                STATUS_ETAPA_3="ALERTA"
                PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 15))
            else
                echo "Nenhum aviso crítico encontrado no log do rkhunter."
            fi
        fi
    else
        echo "[AVISO] rkhunter não está instalado."
        PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 5))
    fi
    echo ""
} >> "$RELATORIO"
atualizar_progresso "$STATUS_ETAPA_3" "Varredura de Rootkits"

# ------------------------------------------------------------------------------
# 4. Auditoria de Sistema com Lynis
# ------------------------------------------------------------------------------
echo "[*] Executando auditoria de hardening com Lynis..."
STATUS_ETAPA_4="OK"
{
    echo "--- AUDITORIA DE SISTEMA (LYNIS) ---"
    if command -v lynis &> /dev/null; then
        lynis audit system --quick --no-colors >> "$RELATORIO"
    else
        echo "[ALERTA] O Lynis não está instalado neste sistema."
        STATUS_ETAPA_4="ALERTA"
        PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 15))
    fi
    echo ""
} >> "$RELATORIO"
atualizar_progresso "$STATUS_ETAPA_4" "Auditoria Lynis"

# ------------------------------------------------------------------------------
# 5. Verificação de Integridade de Pacotes (`debsums`)
# ------------------------------------------------------------------------------
echo "[*] Verificando integridade dos pacotes instalados..."
STATUS_ETAPA_5="OK"
{
    echo "--- INTEGRIDADE DE PACOTES (DEBSUMS) ---"
    if command -v debsums &> /dev/null; then
        RESULT_DEBSUMS=$(debsums -c 2>&1)
        if [ ! -z "$RESULT_DEBSUMS" ]; then
            echo "$RESULT_DEBSUMS"
            echo "Algumas divergências foram encontradas nos arquivos acima."
            STATUS_ETAPA_5="ALERTA"
            PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 25))
        else
            echo "Integridade de pacotes verificada com sucesso. Nenhuma divergência."
        fi
    else
        echo "[AVISO] debsums não está instalado (use 'apt install debsums' para habilitar)."
        PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 5))
    fi
    echo ""
} >> "$RELATORIO"
atualizar_progresso "$STATUS_ETAPA_5" "Verificação de Integridade"

# ------------------------------------------------------------------------------
# 6. Verificação de Pacotes de Proteção Adicionais (Fail2ban & Libpam-tmpdir)
# ------------------------------------------------------------------------------
echo "[*] Verificando pacotes de proteção adicionais..."
STATUS_ETAPA_6="OK"
{
    echo "--- PACOTES DE PROTEÇÃO ADICIONAIS ---"
    
    # Checa Fail2ban
    if dpkg -l | grep -q fail2ban; then
        echo "[OK] fail2ban está instalado."
    else
        echo "[SUGESTÃO] fail2ban não está instalado (recomendado contra força bruta)."
        STATUS_ETAPA_6="ALERTA"
        PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 5))
    fi

    # Checa libpam-tmpdir
    if dpkg -l | grep -q libpam-tmpdir; then
        echo "[OK] libpam-tmpdir está instalado."
    else
        echo "[SUGESTÃO] libpam-tmpdir não está instalado (recomendado para isolar diretórios temporários)."
        STATUS_ETAPA_6="ALERTA"
        PONTUACAO_TOTAL=$((PONTUACAO_TOTAL - 5))
    fi
    echo ""
} >> "$RELATORIO"
atualizar_progresso "$STATUS_ETAPA_6" "Pacotes Adicionais"

# Garante que a pontuação fique no limite seguro de 0 a 100
if [ $PONTUACAO_TOTAL -lt 0 ]; then
    PONTUACAO_TOTAL=0
fi

# Grava o resumo de saúde no relatório
{
    echo "========================================================"
    echo "         DIAGNÓSTICO DE SAÚDE DO SISTEMA               "
    echo " Índice Geral de Segurança: ${PONTUACAO_TOTAL}%"
    echo "========================================================"
} >> "$RELATORIO"

# Exibição Final no Terminal
echo "========================================================"
echo "[*] Auditoria concluída com 100% de progresso!"
echo "[*] Relatório consolidado salvo com sucesso em: $RELATORIO"
echo "--------------------------------------------------------"
if [ $PONTUACAO_TOTAL -ge 80 ]; then
    echo -e "[*] Índice de Saúde do Sistema: ${VERDE}${PONTUACAO_TOTAL}% (Excelente)${RESET}"
elif [ $PONTUACAO_TOTAL -ge 60 ]; then
    echo -e "[*] Índice de Saúde do Sistema: ${AMARELO}${PONTUACAO_TOTAL}% (Bom, com pontos de atenção)${RESET}"
else
    echo -e "[*] Índice de Saúde do Sistema: ${VERMELHO}${PONTUACAO_TOTAL}% (Crítico - Necessita de ajustes)${RESET}"
fi
echo "========================================================"
