@echo off
title Instalador de Softwares para Windows Automatizado
chcp 65001 > nul

:: ==========================================================================
:: VERIFICACAO E SOLICITACAO DE PRIVILEGIOS DE ADMINISTRADOR
:: ==========================================================================
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :rodarScript
) else (
    echo Solicitando privilégios de administrador...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:rodarScript
cls
echo ==========================================================================
echo Passo 1: Reparando e atualizando o gerenciador Winget via PowerShell...
echo ==========================================================================
powershell -Command "Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -Scope CurrentUser"
powershell -Command "Repair-WinGetPackageManager -Force -Latest"

echo.
echo ==========================================================================
echo Passo 2: Criando Ponto de Restauração (INSTALL SOFTWARES)
echo ==========================================================================
echo Aguarde, este processo pode levar alguns segundos...
powershell -Command "Enable-ComputerRestore -Drive 'C:\'" >nul 2>&1
powershell -Command "Checkpoint-Computer -Description 'INSTALL SOFTWARES' -RestorePointType 'APPLICATION_INSTALL'"

if %errorLevel% == 0 (
    echo [SUCESSO] Ponto de restauração criado com êxito!
) else (
    echo [AVISO] Não foi possível criar o ponto. Pode ser que um ponto já tenha sido criado nas últimas 24h.
)
echo.

echo ==========================================================================
echo Passo 3: Instalando programas...
echo ==========================================================================

winget install --id Microsoft.DotNet.Framework.Runtime -e
winget install --id Microsoft.DirectX -e

:: --- Microsoft Visual C++ Redistributables (2005 a 2022) ---
winget install --id Microsoft.VCRedist.2005.x86 -e
winget install --id Microsoft.VCRedist.2005.x64 -e
winget install --id Microsoft.VCRedist.2008.x86 -e
winget install --id Microsoft.VCRedist.2008.x64 -e
winget install --id Microsoft.VCRedist.2010.x86 -e
winget install --id Microsoft.VCRedist.2010.x64 -e
winget install --id Microsoft.VCRedist.2012.x86 -e
winget install --id Microsoft.VCRedist.2012.x64 -e
winget install --id Microsoft.VCRedist.2013.x86 -e
winget install --id Microsoft.VCRedist.2013.x64 -e
winget install --id Microsoft.VCRedist.2015+.x86 -e
winget install --id Microsoft.VCRedist.2015+.x64 -e
:: -----------------------------------------------------------

winget install --id Oracle.JavaRuntimeEnvironment -e -a x86
winget install --id Oracle.JavaRuntimeEnvironment -e -a x64
winget install --id Oracle.JDK.24 -e -a x86
winget install --id Oracle.JDK.24 -e -a x64
winget install --id Mozilla.Firefox.pt-BR -e
winget install --id Google.Chrome -e
winget install --id Brave.Brave -e
winget install --id Oracle.JavaRuntime -e
winget install --id IgorPavlov.7Zip -e
winget install --id RARLab.WinRAR.pt-BR -e
winget install --id Microsoft.Skype -e
winget install --id KLite.CodecPack.Mega -e
winget install --id Adobe.Acrobat.Reader.64-bit -e
winget install --id Foxit.FoxitReader -e
winget install --id VideoLAN.VLC -e
winget install --id Google.Drive -e
winget install --id Zoom.Zoom -e
winget install --id Discord.Discord -e
winget install --id Microsoft.Teams -e
winget install --id Mozilla.Thunderbird.pt-BR -e
winget install --id TheDocumentFoundation.LibreOffice -e
winget install --id ONLYOFFICE.DesktopEditors -e
winget install --id qBittorrent.qBittorrent -e
winget install --id AcroSoftware.CutePDFWriter -e
winget install --id AnyDeskSoftware.AnyDesk -e
winget install --id Notepad++.Notepad++ -e --override "/S /L=pt_BR"

echo.
echo ==========================================================================
echo Passo 4: Atualizando todos os pacotes...
echo ==========================================================================
winget upgrade --all

echo.
echo ==========================================================================
echo INSTALACAO CONCLUÍDA COM SUCESSO!
echo ==========================================================================
pause