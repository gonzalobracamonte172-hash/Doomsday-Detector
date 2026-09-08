#Requires -Version 5.1
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================
# EL SOMBRIO IF - FORENSIC SCANNER (MASTER V9 - NATIVE PS & BARS)
# ============================================================

$script:DefaultModsPath = "$env:APPDATA\.minecraft\mods"

# Base de datos (Sin doomsday para nombres)
$script:IllegalKeywords = @(
    "antighosttotem", "fasttotem", "totemhelper", "autototem", "totem", "switchtotems",
    "acurateblock", "fastplace", "attacktroughgrass", "periodicattack", "toroautoattack",
    "maceattack", "autoclicker", "autoclick", "clicker", "macros", "freecam",
    "tweakeroo", "inventorynext", "hotbaroptimizer", "fastxp", "slotcycler",
    "quickhotkeys", "itemscroller", "autoswitch", "xray",
    "nojumpdelay", "noinputlag", "nohitdelay", "elytrabugfix", "firerocketkey",
    "marrowcrystal", "anchoroptimizer", "quickelytra", "clickcrystals",
    "radarbro", "zansmap", "voxelmap", "xaerosmap",
    "aimbot", "killaura", "reach", "fly", "scaffold", "criticals", "jclicker", "ghostclicker",
    "meteor", "wurst", "aristois", "bleachhack", "mathax", "liquidbounce", 
    "raven", "vape", "novoline", "flux", "impact", "inertia", "kami", "krypton"
)

# Firmas de Bytes Internos
$script:DoomsdayStrings = @(
    "lYgKfQhaCkHofBf", "?WHt4Y", "!hi!kGD@<nS", "%#ksghCP$NIS7$EQuX",
    "jnativehook"
)

$script:WindowsServices = @("dps", "appinfo", "pcasvc", "eventlog", "sysmain", "dusmsvc", "bam")

# ============================================================
# FUNCIONES BASE
# ============================================================
function Get-SafeBytes {
    param([string]$Path)
    try { return [System.IO.File]::ReadAllBytes($Path) } 
    catch {
        try {
            $tempFile = "$env:TEMP\sombrio_scan_$([guid]::NewGuid()).tmp"
            Copy-Item -Path $Path -Destination $tempFile -Force -ErrorAction Stop
            $bytes = [System.IO.File]::ReadAllBytes($tempFile)
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            return $bytes
        } catch { return $null }
    }
}

function Show-Banner {
    Clear-Host
    Write-Host "`n                    Made by zedoon (aka Yaz) @ Mars MC SS team & RL forensics" -ForegroundColor Cyan
    Write-Host "                    Doomsday Client Scanner v1.9.5 (Native Execution & Progress Bars)" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Header {
    param([string]$Subtitle)
    Clear-Host
    Write-Host "`n     ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkRed
    Write-Host "     ║               EL SOMBRIO IF - FORENSIC SCANNER               ║" -ForegroundColor Red
    Write-Host "     ╠══════════════════════════════════════════════════════════════╣" -ForegroundColor DarkRed
    $pad = [math]::Max(0, [math]::Floor((60 - $Subtitle.Length) / 2))
    $str = ((' ' * $pad) + $Subtitle).PadRight(60, ' ')
    Write-Host ("     ║{0}║" -f $str) -ForegroundColor White
    Write-Host "     ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkRed
    Write-Host ""
}

function Pause-Scanner {
    Write-Host "`n     [ Presiona ENTER para regresar al menú principal ]" -ForegroundColor DarkGray
    Read-Host | Out-Null
}

function Show-DetectionBox {
    param([array]$Detections, [string]$Title)
    Write-Host "`n     ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    $pad = [math]::Max(0, [math]::Floor((60 - $Title.Length) / 2))
    $str = ((' ' * $pad) + $Title).PadRight(60, ' ')
    Write-Host "     ║$str║" -ForegroundColor Red
    Write-Host "     ╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Red
    if ($Detections.Count -eq 0) { Write-Host "     ║ No se detectaron anomalías en este escaneo.                  ║" -ForegroundColor Green } 
    else {
        foreach ($item in $Detections) {
            if ($item.Length -gt 56) { $item = $item.Substring(0, 53) + "..." }
            $itemStr = (" > " + $item).PadRight(60, ' ')
            Write-Host "     ║$itemStr║" -ForegroundColor Yellow
        }
    }
    Write-Host "     ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Red
}

function Test-Administrator { return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }

# ============================================================
# [OPCION 1] ANÁLISIS DE MODS
# ============================================================
function Start-FullModScan {
    Show-Header "ANÁLISIS GENERAL DE MODS (.MINECRAFT\MODS)"
    $modsPath = Read-Host "     Ruta de mods [$($script:DefaultModsPath)]"
    if ([string]::IsNullOrWhiteSpace($modsPath)) { $modsPath = $script:DefaultModsPath }
    if (-not (Test-Path -LiteralPath $modsPath)) { Write-Host "`n     [!] La carpeta no existe." -ForegroundColor Red; Pause-Scanner; return }
    
    $files = @(Get-ChildItem -LiteralPath $modsPath -File -ErrorAction SilentlyContinue)
    $hacksEncontrados = [System.Collections.Generic.List[string]]::new()
    
    foreach ($file in $files) {
        $name = $file.BaseName.ToLower() -replace '[\s\-_]', ''
        $isIllegal = $false; $motivo = ""
        foreach ($kw in $script:IllegalKeywords) { if ($name -match $kw) { $isIllegal = $true; $motivo = "Nombre Ilegal ($kw)"; break } }
        
        if (-not $isIllegal -and ($file.Extension -eq ".jar" -or $file.Extension -eq ".zip")) {
            $bytes = Get-SafeBytes -Path $file.FullName
            if ($null -ne $bytes) {
                $contentStr = [System.Text.Encoding]::ASCII.GetString($bytes)
                foreach ($ds in $script:DoomsdayStrings) { if ($contentStr.Contains($ds)) { $isIllegal = $true; $motivo = "Firma Oculta"; break } }
            }
        }
        
        if ($isIllegal) { Write-Host "     [X] $($file.Name) -> $motivo" -ForegroundColor Red; $hacksEncontrados.Add("$($file.Name) ($motivo)") } 
        else { Write-Host "     [+] $($file.Name) -> Legítimo" -ForegroundColor Green }
    }
    Show-DetectionBox -Detections $hacksEncontrados -Title "RESUMEN DE MODS ILEGALES DETECTADOS"
    Pause-Scanner
}

# ============================================================
# [OPCION 2] DETECCIÓN PROFUNDA (JAVA MEMORY + BARRA DE CARGA)
# ============================================================
function Start-DoomsdayMemoryScan {
    Show-Header "DETECCIÓN PROFUNDA (TODOS LOS PROCESOS)"
    Write-Host "     [*] Analizando todos los procesos activos en memoria..." -ForegroundColor Cyan
    
    $allProcs = Get-Process -ErrorAction SilentlyContinue
    $totalProcs = $allProcs.Count
    $inyecciones = [System.Collections.Generic.List[string]]::new()

    for ($i = 0; $i -lt $totalProcs; $i++) {
        $p = $allProcs[$i]
        $porcentaje = [math]::Round((($i + 1) / $totalProcs) * 100)
        
        # BARRA DE CARGA QUE MUESTRA CADA PROCESO
        Write-Progress -Activity "🔍 Rastreo Forense de Memoria" -Status "Escaneando: $($p.ProcessName).exe (PID: $($p.Id))" -PercentComplete $porcentaje

        try {
            $modules = $p.Modules | Select-Object ModuleName, FileName -ErrorAction SilentlyContinue
            if ($modules) {
                foreach ($mod in $modules) {
                    $modName = $mod.ModuleName.ToLower()
                    $modPath = $mod.FileName
                    
                    # 1. Búsqueda de Módulos Ilegales en TODOS los procesos
                    if ($modName -match "jnativehook|meteor|vape|dooms") {
                        $inyecciones.Add("Módulo Ilegal: $modName (PID: $($p.Id))")
                        Write-Host "`n     [X] Inyección detectada en $($p.ProcessName): $modPath" -ForegroundColor Red
                    }
                    
                    # 2. Análisis Profundo (Bytes) SOLO en Java para evitar colapso de RAM
                    if ($p.ProcessName -match "java" -and $modPath -match "\.dll$|\.jar$") {
                        $fileInfo = Get-Item $modPath -ErrorAction SilentlyContinue
                        if ($fileInfo -and $fileInfo.Length -lt 25MB) {
                            $bytes = Get-SafeBytes -Path $modPath
                            if ($null -ne $bytes) {
                                $text = [System.Text.Encoding]::ASCII.GetString($bytes)
                                foreach ($ds in $script:DoomsdayStrings) {
                                    if ($text.Contains($ds)) {
                                        $inyecciones.Add("Firma Hack en: $modName")
                                        Write-Host "`n     [X] Firma inyectada en $($p.ProcessName): $modPath" -ForegroundColor Red
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch {}
    }
    
    Write-Progress -Activity "🔍 Rastreo Forense de Memoria" -Completed
    Show-DetectionBox -Detections $inyecciones -Title "INYECCIONES Y HACKS FANTASMA"
    Pause-Scanner
}

# ============================================================
# [OPCION 3] PREFETCH + REGISTRO BAM
# ============================================================
function Start-SystemScan {
    $todayStr = (Get-Date).ToString("yyyy-MM-dd")
    Show-Header "INTERVENCIÓN RÁPIDA (PREFETCH Y BAM DE HOY $todayStr)"
    if (-not (Test-Administrator)) { Write-Host "     [!] Se requieren privilegios de Administrador para leer BAM."; Pause-Scanner; return }

    $hallazgosAlertas = [System.Collections.Generic.List[string]]::new()

    Write-Host "     [*] Analizando Registro BAM (Ejecuciones Ocultas)..." -ForegroundColor Magenta
    $bamPath = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings\*"
    $bamEntries = Get-ItemProperty $bamPath -ErrorAction SilentlyContinue
    
    foreach ($entry in $bamEntries) {
        $props = $entry.psobject.properties | Where-Object { $_.Name -match "^[a-zA-Z]:\\" }
        foreach ($p in $props) {
            $pName = $p.Name.ToLower()
            if ($pName -match "click|autoclick|macro|jclicker|ghostclicker|meteor|totem|autototem") {
                Write-Host "     [BAM] [HACK / CLICKER] $($p.Name)" -ForegroundColor Red
                $hallazgosAlertas.Add("BAM Oculto: $(Split-Path $p.Name -Leaf)")
            }
        }
    }

    Write-Host "`n     [*] Mostrando actividad del Prefetch de Hoy:`n" -ForegroundColor Cyan
    $prefetchPath = "C:\Windows\Prefetch"
    
    if (Test-Path $prefetchPath) {
        $pfFiles = @(Get-ChildItem -Path $prefetchPath -Filter "*.pf" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
        $encontradosHoy = 0

        foreach ($pf in $pfFiles) {
            if ($pf.LastWriteTime.ToString("yyyy-MM-dd") -eq $todayStr) {
                $encontradosHoy++
                $pName = $pf.Name.ToLower()
                if ($pName -match "click|autoclick|macro|jclicker|ghostclicker|meteor|totem|autototem") {
                    Write-Host "     [!] [HACK / CLICKER] $($pf.Name) | $($pf.LastWriteTime)" -ForegroundColor Red
                    $hallazgosAlertas.Add("$($pf.Name) (Prefetch)")
                } elseif ($pName -like "*java*") {
                    Write-Host "     [+] [JAVA EJECUTADO] $($pf.Name) | $($pf.LastWriteTime)" -ForegroundColor Green
                } else {
                    Write-Host "     [i] [PROCESO] $($pf.Name) | $($pf.LastWriteTime)" -ForegroundColor Gray
                }
            }
        }
        if ($encontradosHoy -eq 0) { Write-Host "     [i] No hay registros para la fecha de hoy." -ForegroundColor Yellow }
    }
    Show-DetectionBox -Detections $hallazgosAlertas -Title "ALERTAS CRÍTICAS EN PREFETCH Y BAM"
    Pause-Scanner
}

# ============================================================
# [OPCION 4] ANÁLISIS DE PAPELERA
# ============================================================
function Start-RecycleBinScan {
    Show-Header "ANÁLISIS DE PAPELERA DE RECICLAJE"
    Write-Host "     [*] Buscando archivos eliminados (Evidencia destruida)...`n" -ForegroundColor White
    $hallazgosPapelera = [System.Collections.Generic.List[string]]::new()
    try {
        $shell = New-Object -ComObject Shell.Application
        $recycleBin = $shell.NameSpace(10)
        foreach ($item in $recycleBin.Items()) {
            $fechaElim = $recycleBin.GetDetailsOf($item, 2)
            Write-Host "     [!] $($item.Name) | Fecha: $fechaElim" -ForegroundColor Red
            if ($item.Name.ToLower() -match "click|macro|ghost|meteor|totem|vape") { $hallazgosPapelera.Add("HACK BORRADO: $($item.Name)") }
        }
    } catch {}
    Show-DetectionBox -Detections $hallazgosPapelera -Title "HACKS DETECTADOS EN LA PAPELERA"
    Pause-Scanner
}

# ============================================================
# [OPCION 5] AUDITORÍA DE MACROS
# ============================================================
function Start-MacroAudit {
    Show-Header "AUDITORÍA DE MACROS Y PERIFÉRICOS"
    Write-Host "     [*] Verificando perfiles de macros de hardware...`n" -ForegroundColor White
    $hallazgosMacros = [System.Collections.Generic.List[string]]::new()
    $pathsToCheck = @(
        @{ Name = "Logitech Gaming"; Path = "$env:USERPROFILE\AppData\Local\Logitech\Logitech Gaming Software\settings.json" },
        @{ Name = "Logitech G HUB"; Path = "$env:USERPROFILE\AppData\Local\LGHUB\settings.db" },
        @{ Name = "Bloody7 Scripts"; Path = "C:\Program Files (x86)\Bloody7\Bloody7\Data\Mouse\English\ScriptsMacros\GunLib\" },
        @{ Name = "Corsair CUE"; Path = "$env:USERPROFILE\AppData\Roaming\Corsair\CUE\Config.cuecfg" },
        @{ Name = "Razer Synapse"; Path = "C:\ProgramData\Razer\Synapse3\Log\SynapseService.log" }
    )
    foreach ($item in $pathsToCheck) {
        if (Test-Path $item.Path) {
            $extraInfo = "Instalado"
            if ($item.Name -eq "Corsair CUE" -and (Get-Content $item.Path -Raw -ErrorAction SilentlyContinue) -match "RecMouseClicksEnable") { 
                $extraInfo = "MACRO ACTIVA"; $hallazgosMacros.Add("$($item.Name) - Macro Activa")
            } else { $hallazgosMacros.Add("$($item.Name) Detectado") }
            Write-Host "     [!] $($item.Name) [$extraInfo] -> Ruta: $($item.Path)" -ForegroundColor Yellow
        }
    }
    Show-DetectionBox -Detections $hallazgosMacros -Title "SOFTWARE DE MACROS DETECTADO"
    Pause-Scanner
}

# ============================================================
# [OPCION 6] KILLER SCREEN (DIFF)
# ============================================================
function Start-DiffKiller {
    Show-Header "FINALIZADOR DE PROCESOS OCULTOS (DIFF)"
    $forbidden = @("obs","obs32","obs64","discord","streamlabs","bandicam","sharex","gamebar")
    $detected = @()
    foreach ($proc in Get-Process -ErrorAction SilentlyContinue) {
        if ($forbidden -contains $proc.Name.ToLower()) {
            $detected += $proc.Name
            Write-Host "     [!] Proceso de grabación detectado: $($proc.Name) [Ejecutándose]" -ForegroundColor Yellow
        }
    }
    if ($detected.Count -eq 0) { Write-Host "`n     [+] No hay procesos prohibidos activos." -ForegroundColor Green; Pause-Scanner; return }
    $choice = Read-Host "`n     ¿Forzar cierre de todos los procesos de grabación? (S/N)"
    if ($choice.ToUpper() -eq "S") {
        foreach ($name in $detected) {
            Get-Process -Name $name -ErrorAction SilentlyContinue | Stop-Process -Force
            Write-Host "     [Terminado] $name.exe" -ForegroundColor Red
        }
    }
    Pause-Scanner
}

# ============================================================
# [OPCION 7] SERVICIOS WINDOWS
# ============================================================
function Show-WindowsServices {
    Show-Header "ESTADO DE SERVICIOS WINDOWS (FORENSIC)"
    $hallazgosSvc = [System.Collections.Generic.List[string]]::new()
    foreach ($service in $script:WindowsServices) {
        $output = @(& sc.exe query $service 2>&1)
        $text = ($output -join "`n")
        $state = "DESCONOCIDO"; $color = "Gray"
        if ($text -match 'RUNNING') { $state = "EJECUTÁNDOSE"; $color = "Green" }
        elseif ($text -match 'STOPPED') { 
            $state = "DETENIDO"; $color = "Red" 
            if ($service -eq "pcasvc" -or $service -eq "bam" -or $service -eq "sysmain") { $hallazgosSvc.Add("Servicio Crítico Apagado: $service") }
        } elseif ($text -match '1060') { $state = "NO ENCONTRADO"; $color = "Red" }
        Write-Host "     - Servicio: $($service.ToUpper()) | Estado: $state" -ForegroundColor $color
    }
    Show-DetectionBox -Detections $hallazgosSvc -Title "ALERTAS DE SERVICIOS APAGADOS"
    Pause-Scanner
}

# ============================================================
# [OPCION 8] ANÁLISIS DE DLLs MODIFICADAS (1 MES)
# ============================================================
function Start-DllScan {
    Show-Header "ANÁLISIS DE DLLs DEL SISTEMA MODIFICADAS"
    if (-not (Test-Administrator)) { Write-Host "     [!] Se requiere Administrador."; Pause-Scanner; return }
    Write-Host "     [*] Escaneando DLLs alteradas en el ÚLTIMO MES (30 días)..." -ForegroundColor Cyan
    $limitDate = (Get-Date).AddDays(-30)
    $systemPaths = @("$env:SystemRoot\System32", "$env:SystemRoot\SysWOW64")
    $hallazgosDLL = [System.Collections.Generic.List[string]]::new()
    foreach ($path in $systemPaths) {
        if (-not (Test-Path $path)) { continue }
        $dllFiles = @(Get-ChildItem -Path $path -Filter "*.dll" -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -ge $limitDate })
        foreach ($file in $dllFiles) {
            try {
                $sig = Get-AuthenticodeSignature $file.FullName -ErrorAction SilentlyContinue
                if ($sig.Status -ne 'Valid') {
                    Write-Host "     [!] DLL Anómala: $($file.Name) | Modificada: $($file.LastWriteTime)" -ForegroundColor Red
                    $hallazgosDLL.Add("$($file.Name) (Sin Firma)")
                }
            } catch {}
        }
    }
    Show-DetectionBox -Detections $hallazgosDLL -Title "DLLs ANÓMALAS O SIN FIRMA (ÚLTIMO MES)"
    Pause-Scanner
}

# ============================================================
# [OPCION 9] HUB DE HERRAMIENTAS SS (EJECUCIÓN NATIVA)
# ============================================================
function Start-SSToolsHub {
    Show-Header "HUB DE HERRAMIENTAS SS (EJECUCIÓN Y DESCARGAS)"
    Write-Host "     [*] Apps .exe se ejecutarán al instante. Otros links abrirán el navegador.`n" -ForegroundColor Cyan

    $tools = @(
        [PSCustomObject]@{ Id=1; Name="Journaltrace Spookwn"; Url="https://github.com/spokwn/journaltrace"; Icon="▶" }
        [PSCustomObject]@{ Id=2; Name="Echo Journal Trace"; Url="https://dl.echo.ac/tool/journal"; Icon="▶" }
        [PSCustomObject]@{ Id=3; Name="Process Hacker"; Url="https://sourceforge.net/projects/processhacker/files/processhacker2/processhacker-2.39-setup.exe/download"; Icon="✦" }
        [PSCustomObject]@{ Id=4; Name="System Informer"; Url="https://sourceforge.net/projects/systeminformer/files/latest/download"; Icon="✦" }
        [PSCustomObject]@{ Id=5; Name="WinPrefetchView"; Url="https://www.nirsoft.net/utils/winprefetchview-x64.zip"; Icon="📜" }
        [PSCustomObject]@{ Id=6; Name="WinPrefetchView ++"; Url="https://github.com/Orbdiff/PrefetchView/releases/download/v1.6.1/PrefetchView++.exe"; Icon="📜" }
        [PSCustomObject]@{ Id=7; Name="Everything"; Url="https://www.voidtools.com/Everything-1.4.1.1026.x86-Setup.exe"; Icon="🔎" }
        [PSCustomObject]@{ Id=8; Name="Asistente De Recuva"; Url="https://www.ccleaner.com/es-es/recuva/download/standard"; Icon="🗑" }
        [PSCustomObject]@{ Id=9; Name="PreviousFilesRecovery"; Url="https://www.nirsoft.net/utils/previousfilesrecovery-x64.zip"; Icon="🗑" }
        [PSCustomObject]@{ Id=10; Name="BrowserDownloadViewer"; Url="https://www.majorgeeks.com/mg/get/browserdownloadsview,2.html"; Icon="➤" }
        [PSCustomObject]@{ Id=11; Name="ExecutedProgramsList"; Url="https://www.nirsoft.net/utils/executedprogramslist.zip"; Icon="➤" }
        [PSCustomObject]@{ Id=12; Name="Usb Deview Viewer"; Url="https://dl.echo.ac/tool/usb"; Icon="➤" }
        [PSCustomObject]@{ Id=13; Name="LastActivityView"; Url="https://www.nirsoft.net/utils/lastactivityview.zip"; Icon="➤" }
        [PSCustomObject]@{ Id=14; Name="UninstallView"; Url="https://www.nirsoft.net/utils/uninstallview-x64.zip"; Icon="➤" }
        [PSCustomObject]@{ Id=15; Name="DoomsdayFucker"; Url="https://github.com/MeowTonynoh/MeowDoomsdayFucker/releases"; Icon="⚡" }
        [PSCustomObject]@{ Id=16; Name="NovoWareFucker"; Url="https://github.com/MeowTonynoh/MeowNovowareFucker/releases"; Icon="⚡" }
        [PSCustomObject]@{ Id=17; Name="ClientFucker"; Url="https://github.com/MeowTonynoh/MeowClientFucker/releases"; Icon="⚡" }
        [PSCustomObject]@{ Id=18; Name="MeowResolver"; Url="https://github.com/MeowTonynoh/MeowResolver/releases"; Icon="⚡" }
        [PSCustomObject]@{ Id=19; Name="InjGen"; Url="https://github.com/Orbdiff/InjGen/"; Icon="⚡" }
        [PSCustomObject]@{ Id=20; Name="DetectItEasy"; Url="https://github.com/horsicq/Detect-It-Easy/releases"; Icon="⚡" }
        [PSCustomObject]@{ Id=21; Name="PathParser"; Url="https://github.com/spokwn/PathsParser/releases/"; Icon="⚡" }
        [PSCustomObject]@{ Id=22; Name="SStool"; Url="https://github.com/Orbdiff/SSTool/releases/tag/update"; Icon="⚡" }
        [PSCustomObject]@{ Id=23; Name="Red Lotus Downloader"; Url="https://github.com/ItzIceHere/RedLotus-Tool-Downloader"; Icon="⚡" }
        [PSCustomObject]@{ Id=24; Name="checkdeleteUNS"; Url="https://github.com/orbdiff/checkdeletedusn"; Icon="⚡" }
        [PSCustomObject]@{ Id=25; Name="bamparser"; Url="https://github.com/spokwn/BAM-parser/releases"; Icon="📝" }
        [PSCustomObject]@{ Id=26; Name="luyten"; Url="https://github.com/deathmarine/Luyten/releases/download/v0.5.4_Rebuilt_with_Latest_depenencies/luyten-0.5.4.exe"; Icon="📈" }
        [PSCustomObject]@{ Id=27; Name="Win10Live info"; Url="https://github.com/kacos2000/Win10LiveInfo/releases"; Icon="⊞" }
        [PSCustomObject]@{ Id=28; Name="Ocean Anticheat"; Url="https://anticheat.ac/download/"; Icon="⚡" }
        [PSCustomObject]@{ Id=29; Name="Echo Anticheat"; Url="https://echo.ac/free"; Icon="⚡" }
    )

    foreach ($t in $tools) {
        $idPad = $t.Id.ToString().PadLeft(2, ' ')
        Write-Host "     [$idPad] $($t.Icon) $($t.Name)" -ForegroundColor White
    }

    while ($true) {
        $choice = (Read-Host "`n     Ingresa el número para EJECUTAR/ABRIR la herramienta (o 0 para salir)").Trim()
        if ($choice -eq "0") { break }
        
        $selected = $tools | Where-Object { $_.Id.ToString() -eq $choice }
        if ($selected) {
            # Si el enlace termina en .exe (o similar), lo descargamos y ejecutamos al instante
            if ($selected.Url -match "\.exe$" -or $selected.Url -match "download$") {
                Write-Host "     [*] Descargando $($selected.Name) en directorio temporal..." -ForegroundColor Cyan
                $exeName = ($selected.Name -replace '\s','_') + ".exe"
                $exePath = "$env:TEMP\$exeName"
                try {
                    Write-Progress -Activity "Descargando Herramienta" -Status $selected.Name
                    Invoke-WebRequest -Uri $selected.Url -OutFile $exePath -UseBasicParsing
                    Write-Progress -Activity "Descargando Herramienta" -Completed
                    Write-Host "     [+] Ejecutando $($selected.Name)..." -ForegroundColor Green
                    Start-Process $exePath -Wait
                } catch { Write-Host "     [!] Error de descarga." -ForegroundColor Red }
            } else {
                Write-Host "     [+] Abriendo $($selected.Name) en el navegador..." -ForegroundColor Green
                Start-Process $selected.Url
            }
        } else { Write-Host "     [!] Opción inválida. Intenta nuevamente." -ForegroundColor Red }
    }
}

# ============================================================
# [OPCION 10] HUB DE PAYLOADS GITHUB (INYECCIÓN DIRECTA EN POWERSHELL)
# ============================================================
function Start-RemoteScript {
    Show-Header "EJECUCIÓN NATIVA DE SCRIPTS REMOTOS"
    if (-not (Test-Administrator)) { Write-Host "     [!] Se requiere Administrador."; Pause-Scanner; return }

    Write-Host "     [*] Selecciona el script para inyectar directamente en ESTA consola:`n" -ForegroundColor Cyan

    $payloads = @(
        [PSCustomObject]@{ Id=1; Name="Zedoon DoomsDayDetector"; Url="https://raw.githubusercontent.com/zedoonvm1/powershell-scripts/refs/heads/main/DoomsDayDetector.ps1" }
        [PSCustomObject]@{ Id=2; Name="Lilith Services"; Url="https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Services.ps1" }
        [PSCustomObject]@{ Id=3; Name="Lilith Service-Enabler"; Url="https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Service-Enabler.ps1" }
        [PSCustomObject]@{ Id=4; Name="Ordiff Kill ScreenRecording"; Url="https://raw.githubusercontent.com/Orbdiff/powershell/refs/heads/main/kill-screen-processes.ps1" }
        [PSCustomObject]@{ Id=5; Name="Lilith DoomsdayFinder"; Url="https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/DoomsdayFinder.ps1" }
        [PSCustomObject]@{ Id=6; Name="14rpSucks dd-finder"; Url="https://raw.githubusercontent.com/l4rpsucks/Scripts/refs/heads/main/dd-finder.ps1" }
        [PSCustomObject]@{ Id=7; Name="Ordiff JARParser"; Url="https://raw.githubusercontent.com/Orbdiff/JARParser/refs/heads/main/JARParser.ps1" }
        [PSCustomObject]@{ Id=8; Name="NoDiff-del JARParser"; Url="https://raw.githubusercontent.com/NoDiff-del/JARParser/refs/heads/main/JARParser.ps1" }
        [PSCustomObject]@{ Id=9; Name="RedLotus BamParser"; Url="https://raw.githubusercontent.com/PureIntent/ScreenShare/main/RedLotusBam.ps1" }
        [PSCustomObject]@{ Id=10; Name="Spouken BamParser"; Url="https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/bamparser.ps1" }
        [PSCustomObject]@{ Id=11; Name="MeowTonynoh Mod Analyzer"; Url="https://raw.githubusercontent.com/MeowTonynoh/MeowModAnalyzer/main/MeowModAnalyzer.ps1" }
        [PSCustomObject]@{ Id=12; Name="RedLotus Prefetch Integrity"; Url="https://raw.githubusercontent.com/bacanoicua/Screenshare/main/RedLotusPrefetchIntegrityAnalyzer.ps1" }
        [PSCustomObject]@{ Id=13; Name="Florinyoq Bam Deleted Keys"; Url="https://raw.githubusercontent.com/Florinyoq/Screenshare/refs/heads/main/bam.ps1" }
        [PSCustomObject]@{ Id=14; Name="14rpSucks MiniSS"; Url="https://raw.githubusercontent.com/l4rpsucks/Scripts/refs/heads/main/miniss.ps1" }
    )

    foreach ($p in $payloads) {
        $idPad = $p.Id.ToString().PadLeft(2, ' ')
        Write-Host "     [$idPad] $($p.Name)" -ForegroundColor White
    }

    Write-Host "`n     [0] Regresar al Menú Principal" -ForegroundColor Red
    
    $choice = (Read-Host "`n     Ingresa el número para inyectar el Payload").Trim()
    if ($choice -eq "0") { return }
    
    $selected = $payloads | Where-Object { $_.Id.ToString() -eq $choice }
    if ($selected) {
        Write-Host "`n     [*] Descargando y ejecutando '$($selected.Name)' de forma silenciosa..." -ForegroundColor Yellow
        try {
            # Inyección limpia dentro del mismo PowerShell sin usar CMD
            $scriptContent = Invoke-RestMethod -Uri $selected.Url -UseBasicParsing
            Invoke-Expression $scriptContent
            Write-Host "`n     [+] Ejecución finalizada con éxito en la memoria." -ForegroundColor Green
        } catch { 
            Write-Host "`n     [!] Error al ejecutar el script: $($_.Exception.Message)" -ForegroundColor Red 
        }
    } else { Write-Host "     [!] Opción inválida." -ForegroundColor Red }

    Pause-Scanner
}

# ============================================================
# [OPCION 11] EJECUTAR JOURNALTRACE AUTO
# ============================================================
function Start-JournalTrace {
    Show-Header "ANÁLISIS DE USN JOURNAL (JOURNALTRACE)"
    if (-not (Test-Administrator)) { Write-Host "     [!] Se requiere Administrador."; Pause-Scanner; return }
    $url = "https://github.com/ponei/JournalTrace/releases/download/1.0/JournalTrace.exe"
    $exePath = "$env:TEMP\JournalTrace.exe"
    if (-not (Test-Path $exePath)) {
        Write-Host "     [*] Descargando JournalTrace desde GitHub..." -ForegroundColor Cyan
        try {
            Write-Progress -Activity "Descargando JournalTrace" -Status "Descargando..."
            Invoke-WebRequest -Uri $url -OutFile $exePath -UseBasicParsing
            Write-Progress -Activity "Descargando JournalTrace" -Completed
            Write-Host "     [+] Descarga completada." -ForegroundColor Green
        } catch { Write-Host "     [!] Error de descarga." -ForegroundColor Red; Pause-Scanner; return }
    }
    Write-Host "     [*] Ejecutando JournalTrace en esta consola...`n" -ForegroundColor Yellow
    try { Start-Process -FilePath $exePath -NoNewWindow -Wait -PassThru | Out-Null; Write-Host "`n     [✔] Ejecución finalizada." -ForegroundColor Green } catch {}
    Pause-Scanner
}

# ============================================================
# [OPCION 12] ANÁLISIS COMPLETO DEL DISCO
# ============================================================
function Start-FullDiskScan {
    Show-Header "ANÁLISIS COMPLETO DEL DISCO"
    Write-Host "     [*] Escaneando C:\Users en busca de clientes ocultos..." -ForegroundColor Cyan
    Write-Host "     [i] Por favor espera, esto puede tomar varios minutos.`n" -ForegroundColor DarkGray
    $hallazgosDisco = [System.Collections.Generic.List[string]]::new()
    $pathsToScan = @("C:\Users")
    foreach ($path in $pathsToScan) {
        if (Test-Path $path) {
            $files = Get-ChildItem -Path $path -Recurse -File -Include "*.jar","*.exe","*.dll" -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -match "clicker|autoclick|ghost|meteor|wurst|aristois|vape|raven|krypton|totem|doomsday|dooms"
            }
            foreach ($f in $files) {
                Write-Host "     [!] Hack Oculto: $($f.Name)" -ForegroundColor Red
                Write-Host "         Ruta: $($f.FullName)" -ForegroundColor Yellow
                $hallazgosDisco.Add("$($f.Name) | Carpeta: $($f.Directory.Name)")
            }
        }
    }
    Show-DetectionBox -Detections $hallazgosDisco -Title "ARCHIVOS SOSPECHOSOS EN EL DISCO"
    Pause-Scanner
}

# ============================================================
# [OPCION 13] RUTAS DE ANÁLISIS MANUAL (WIN + R)
# ============================================================
function Start-WinRCommands {
    Show-Header "RUTAS DE ANÁLISIS MANUAL (WINDOWS + R)"
    Write-Host "     [*] Rutas rápidas para ejecución manual o análisis visual...`n" -ForegroundColor Cyan
    $rutas = @(
        [PSCustomObject]@{ Id=1;  Cmd="C:\`$Recycle.bin"; Desc="Archivos eliminados (Papelera)" }
        [PSCustomObject]@{ Id=2;  Cmd="regedit"; Desc="Registro negativo de windows" }
        [PSCustomObject]@{ Id=3;  Cmd="C:\Windows\Prefetch"; Desc="Programas ejecutados (Javaw.pf)" }
        [PSCustomObject]@{ Id=4;  Cmd="$env:TEMP"; Desc="JnativeHook ➜ dependencia autoclickers viejos" }
        [PSCustomObject]@{ Id=5;  Cmd="$env:APPDATA\.minecraft"; Desc="Buscar en mods/versions/logs/resourcepacks" }
        [PSCustomObject]@{ Id=6;  Cmd="shell:recent"; Desc="Archivos ejecutados recientemente" }
        [PSCustomObject]@{ Id=7;  Cmd="$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine"; Desc="Historial comandos PowerShell" }
        [PSCustomObject]@{ Id=8;  Cmd="msinfo32"; Desc="Virtual machine = ban" }
        [PSCustomObject]@{ Id=9;  Cmd="C:\Windows\System32\drivers\etc"; Desc="Hosts bloqueados" }
        [PSCustomObject]@{ Id=10; Cmd="$env:LOCALAPPDATA\Microsoft\Windows\History"; Desc="Páginas y archivos ejecutados" }
    )
    foreach ($r in $rutas) {
        $idPad = $r.Id.ToString().PadLeft(2, ' ')
        Write-Host "     [$idPad] Comando: " -NoNewline -ForegroundColor White
        Write-Host ($r.Cmd).PadRight(60, ' ') -NoNewline -ForegroundColor Yellow
        Write-Host "`n          ➜ $($r.Desc)" -ForegroundColor Gray
    }
    Write-Host "`n     [0] Regresar al Menú Principal" -ForegroundColor Red
    while ($true) {
        $choice = (Read-Host "`n     Ingresa el número para ABRIR la ruta (o 0 para salir)").Trim()
        if ($choice -eq "0") { break }
        $selected = $rutas | Where-Object { $_.Id.ToString() -eq $choice }
        if ($selected) {
            Write-Host "     [+] Abriendo $($selected.Cmd)..." -ForegroundColor Green
            try {
                if ($selected.Cmd -eq "regedit" -or $selected.Cmd -eq "msinfo32") { Start-Process $selected.Cmd } 
                else { Start-Process "explorer.exe" $selected.Cmd }
            } catch { Write-Host "     [!] No se pudo abrir la ruta. Verifica permisos o existencia." -ForegroundColor Red }
        } else { Write-Host "     [!] Opción inválida. Intenta nuevamente." -ForegroundColor Red }
    }
}

# ============================================================
# MENÚ PRINCIPAL
# ============================================================
function Show-MainMenu {
    while ($true) {
        try {
            Show-Banner
            Write-Host "     ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkRed
            Write-Host "     ║               MODO: INTERVENCIÓN Y AUDITORÍA                 ║" -ForegroundColor White
            Write-Host "     ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkRed
            Write-Host "`n       [1] Analizar Mods (.minecraft\mods)       [8] Análisis DLLs (1 MES)" -ForegroundColor White
            Write-Host "       [2] Detección Profunda Hacks                [9] Hub Herramientas SS" -ForegroundColor Yellow
            Write-Host "       [3] Intervención Rápida (Prefetch/BAM)      [10] Hub Payloads (GitHub)" -ForegroundColor White
            Write-Host "       [4] Análisis Papelera de Reciclaje         [11] Ejecutar JournalTrace" -ForegroundColor White
            Write-Host "       [5] Auditoría de Macros                    [12] Análisis Completo del Disco" -ForegroundColor Cyan
            Write-Host "       [6] Killer Screen (Diff)                   [13] Rutas Manuales (Win + R)" -ForegroundColor Magenta
            Write-Host "       [7] Servicios Windows                      [14] Salir de la Aplicación" -ForegroundColor Red
            Write-Host "`n     ----------------------------------------------------------------" -ForegroundColor DarkGray
            
            $option = (Read-Host "`n     Selecciona una opción [1-14]").Trim()
            switch ($option) {
                "1" { Start-FullModScan }
                "2" { Start-DoomsdayMemoryScan }
                "3" { Start-SystemScan }
                "4" { Start-RecycleBinScan }
                "5" { Start-MacroAudit }
                "6" { Start-DiffKiller }
                "7" { Show-WindowsServices }
                "8" { Start-DllScan }
                "9" { Start-SSToolsHub }
                "10"{ Start-RemoteScript }
                "11"{ Start-JournalTrace }
                "12"{ Start-FullDiskScan }
                "13"{ Start-WinRCommands }
                "14"{ Clear-Host; Write-Host "`n     ¡Hasta luego, Joaquín!`n" -ForegroundColor Red; return }
                default { Write-Host "`n     [!] Opción inválida." -ForegroundColor Red; Start-Sleep -Seconds 1 }
            }
        } catch {
            Write-Host "`n     [!] Protección activada. El script evitó un cierre inesperado." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}

Show-MainMenu
