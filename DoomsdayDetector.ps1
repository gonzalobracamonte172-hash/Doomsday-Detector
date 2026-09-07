#Requires -Version 5.1
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================
# EL SOMBRIO IF - FORENSIC SCANNER (MASTER FIX & BOX EDITION)
# ============================================================

$script:DefaultModsPath = "$env:APPDATA\.minecraft\mods"

# Base de datos ampliada (Se borró "doomsday" y "dooms" de la lista como se solicitó)
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

$script:DoomsdayStrings = @(
    "lYgKfQhaCkHofBf", "?WHt4Y", "!hi!kGD@<nS", "%#ksghCP$NIS7$EQuX",
    "jnativehook"
)

# ============================================================
# LECTOR DE ARCHIVOS BLINDADO (EVITA CIERRES Y ERRORES)
# ============================================================
function Get-SafeBytes {
    param([string]$Path)
    try {
        # Intenta leer directamente
        return [System.IO.File]::ReadAllBytes($Path)
    } catch {
        try {
            # Si Java lo está usando, lo copia a una carpeta temporal y lo lee desde ahí
            $tempFile = "$env:TEMP\sombrio_scan_$([guid]::NewGuid()).tmp"
            Copy-Item -Path $Path -Destination $tempFile -Force -ErrorAction Stop
            $bytes = [System.IO.File]::ReadAllBytes($tempFile)
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            return $bytes
        } catch {
            return $null
        }
    }
}

# ============================================================
# INTERFAZ, BANNER Y CUADROS (SQUARE)
# ============================================================
function Show-Banner {
    Clear-Host
    Write-Host "`n                    Made by zedoon (aka Yaz) @ Mars MC SS team & RL forensics" -ForegroundColor Cyan
    Write-Host "                    Doomsday Client Scanner v1.5 (Safe Memory & Prefetch)" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Header {
    param([string]$Subtitle)
    Clear-Host
    Write-Host "`n     ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkRed
    Write-Host "     ║               EL SOMBRIO IF - FORENSIC SCANNER               ║" -ForegroundColor Red
    Write-Host "     ╠══════════════════════════════════════════════════════════════╣" -ForegroundColor DarkRed
    $pad = [math]::Max(0, [math]::Floor((60 - $Subtitle.Length) / 2))
    $str = (' ' * $pad) + $Subtitle
    $str = $str.PadRight(60, ' ')
    Write-Host ("     ║{0}║" -f $str) -ForegroundColor White
    Write-Host "     ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkRed
    Write-Host ""
}

function Pause-Scanner {
    Write-Host "`n     [ Presiona ENTER para regresar al menú principal ]" -ForegroundColor DarkGray
    Read-Host | Out-Null
}

# FUNCIÓN DEL CUADRO DE DETECCIONES
function Show-DetectionBox {
    param([array]$Detections, [string]$Title)
    Write-Host "`n     ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    $pad = [math]::Max(0, [math]::Floor((60 - $Title.Length) / 2))
    $str = (' ' * $pad) + $Title
    $str = $str.PadRight(60, ' ')
    Write-Host "     ║$str║" -ForegroundColor Red
    Write-Host "     ╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Red
    
    if ($Detections.Count -eq 0) {
        Write-Host "     ║ No se detectaron anomalías en este escaneo.                  ║" -ForegroundColor Green
    } else {
        foreach ($item in $Detections) {
            # Acortar texto si es muy largo para que no rompa la caja
            if ($item.Length -gt 56) { $item = $item.Substring(0, 53) + "..." }
            $itemStr = " > " + $item
            $itemStr = $itemStr.PadRight(60, ' ')
            Write-Host "     ║$itemStr║" -ForegroundColor Yellow
        }
    }
    Write-Host "     ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Red
}

# ============================================================
# MÓDULO 1: ANÁLISIS DE MODS (INTACTO COMO PEDISTE)
# ============================================================
function Start-FullModScan {
    Show-Header "ANÁLISIS GENERAL DE MODS (.MINECRAFT\MODS)"
    $modsPath = Read-Host "     Ruta de mods [$($script:DefaultModsPath)]"
    if ([string]::IsNullOrWhiteSpace($modsPath)) { $modsPath = $script:DefaultModsPath }

    if (-not (Test-Path -LiteralPath $modsPath)) {
        Write-Host "`n     [!] La carpeta no existe." -ForegroundColor Red; Pause-Scanner; return
    }

    $files = @(Get-ChildItem -LiteralPath $modsPath -File -ErrorAction SilentlyContinue)
    Write-Host "     [*] Analizando $($files.Count) archivos en busca de firmas y nombres ilegales...`n" -ForegroundColor White

    $javaProc = Get-Process -Name "javaw", "java" -ErrorAction SilentlyContinue
    $hacksEncontrados = [System.Collections.Generic.List[string]]::new()

    foreach ($file in $files) {
        $name = $file.BaseName.ToLower() -replace '[\s\-_]', ''
        $isIllegal = $false
        $motivo = ""

        # 1. Búsqueda por Nombre (Autototem, Meteor, etc)
        foreach ($kw in $script:IllegalKeywords) {
            if ($name -match $kw) { 
                $isIllegal = $true; $motivo = "Nombre Ilegal ($kw)"
                break 
            }
        }

        # 2. Búsqueda Profunda (Interior del archivo)
        if (-not $isIllegal -and ($file.Extension -eq ".jar" -or $file.Extension -eq ".zip")) {
            $bytes = Get-SafeBytes -Path $file.FullName
            if ($null -ne $bytes) {
                $contentStr = [System.Text.Encoding]::ASCII.GetString($bytes)
                foreach ($ds in $script:DoomsdayStrings) {
                    if ($contentStr.Contains($ds)) {
                        $isIllegal = $true; $motivo = "Firma Oculta"
                        break
                    }
                }
            }
        }

        if ($isIllegal) {
            Write-Host "     [X] $($file.Name) -> $motivo" -ForegroundColor Red
            $hacksEncontrados.Add("$($file.Name) ($motivo)")
        } else {
            Write-Host "     [+] $($file.Name) -> Legítimo" -ForegroundColor Green
        }
    }

    # Mostrar la tabla cuadrada final
    Show-DetectionBox -Detections $hacksEncontrados -Title "RESUMEN DE MODS ILEGALES DETECTADOS"
    Pause-Scanner
}

# ============================================================
# MÓDULO 2: DETECCIÓN PROFUNDA (JAVA MEMORY / INYECCIONES)
# ============================================================
function Start-DoomsdayMemoryScan {
    Show-Header "DETECCIÓN PROFUNDA (HACKS INYECTADOS / RENOMBRADOS)"
    Write-Host "     [*] Analizando módulos cargados en los procesos de Java..." -ForegroundColor Cyan
    Write-Host "     [i] Esto detecta DLLs renombradas inyectadas en el juego.`n" -ForegroundColor DarkGray

    $javaProcs = Get-Process -Name "javaw", "java" -ErrorAction SilentlyContinue
    $inyecciones = [System.Collections.Generic.List[string]]::new()

    if (-not $javaProcs) {
        Write-Host "     [i] No hay procesos de Java en ejecución." -ForegroundColor Yellow
    } else {
        foreach ($p in $javaProcs) {
            try {
                foreach ($mod in $p.Modules) {
                    $modName = $mod.ModuleName.ToLower()
                    $modPath = $mod.FileName
                    $detectado = $false
                    
                    # Chequeo de nombres de módulos
                    if ($modName -match "jnativehook|meteor|vape") {
                        $inyecciones.Add("Módulo Ilegal: $modName (PID: $($p.Id))")
                        $detectado = $true
                    }
                    # Chequeo interno (DLLs inyectadas y renombradas)
                    elseif ($modPath -match "\.dll$|\.jar$") {
                        # Solo lee archivos pequeños para no trabar la PC
                        $fileInfo = Get-Item $modPath -ErrorAction SilentlyContinue
                        if ($fileInfo -and $fileInfo.Length -lt 25MB) {
                            $bytes = Get-SafeBytes -Path $modPath
                            if ($null -ne $bytes) {
                                $text = [System.Text.Encoding]::ASCII.GetString($bytes)
                                foreach ($ds in $script:DoomsdayStrings) {
                                    if ($text.Contains($ds)) {
                                        $inyecciones.Add("Firma Hack en: $modName")
                                        $detectado = $true
                                        break
                                    }
                                }
                            }
                        }
                    }

                    if ($detectado) { Write-Host "     [X] Inyección interceptada: $modPath" -ForegroundColor Red }
                }
            } catch {}
        }
    }

    Show-DetectionBox -Detections $inyecciones -Title "INYECCIONES Y HACKS FANTASMA EN JAVA"
    Pause-Scanner
}

# ============================================================
# MÓDULO 3: PREFETCH DEL DÍA (MUESTRA TODO LO DE HOY, JAVA VERDE, AUTOCLICK ROJO)
# ============================================================
function Start-SystemScan {
    $todayStr = (Get-Date).ToString("yyyy-MM-dd")
    Show-Header "INTERVENCIÓN RÁPIDA (PREFETCH DE HOY $todayStr)"
    
    $prefetchPath = "C:\Windows\Prefetch"
    $hallazgosPrefetch = [System.Collections.Generic.List[string]]::new()

    if (Test-Path $prefetchPath) {
        $pfFiles = @(Get-ChildItem -Path $prefetchPath -Filter "*.pf" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
        $encontradosHoy = 0

        Write-Host "     [*] Mostrando toda la actividad registrada hoy en Prefetch:`n" -ForegroundColor Cyan

        foreach ($pf in $pfFiles) {
            if ($pf.LastWriteTime.ToString("yyyy-MM-dd") -eq $todayStr) {
                $encontradosHoy++
                $pName = $pf.Name.ToLower()

                # ROJO: Hacks, Autoclickers y Totem (Sin dooms)
                if ($pName -match "click|autoclick|macro|jclicker|ghostclicker|meteor|totem|autototem") {
                    Write-Host "     [!] [HACK / CLICKER] $($pf.Name) | $($pf.LastWriteTime)" -ForegroundColor Red
                    $hallazgosPrefetch.Add("$($pf.Name) (Hack/Clicker)")
                } 
                # VERDE: Java / Javaw
                elseif ($pName -like "*java*") {
                    Write-Host "     [+] [JAVA EJECUTADO] $($pf.Name) | $($pf.LastWriteTime)" -ForegroundColor Green
                } 
                # GRIS: Resto de procesos de hoy (DESCOMENTADO)
                else {
                    Write-Host "     [i] [PROCESO] $($pf.Name) | $($pf.LastWriteTime)" -ForegroundColor Gray
                }
            }
        }
        if ($encontradosHoy -eq 0) { Write-Host "     [i] No hay registros para la fecha de hoy." -ForegroundColor Yellow }
    } else {
        Write-Host "     [!] Carpeta Prefetch no encontrada o sin permisos." -ForegroundColor Red
    }

    Show-DetectionBox -Detections $hallazgosPrefetch -Title "HACKS Y CLICKERS EN EL PREFETCH DE HOY"
    Pause-Scanner
}

# ============================================================
# MÓDULO 11: ANÁLISIS DEL DISCO (OPCIÓN 11)
# ============================================================
function Start-FullDiskScan {
    Show-Header "ANÁLISIS COMPLETO DEL DISCO"
    Write-Host "     [*] Escaneando C:\Users en busca de clientes ocultos..." -ForegroundColor Cyan
    Write-Host "     [i] Por favor espera, esto puede tomar varios minutos.`n" -ForegroundColor DarkGray

    $hallazgosDisco = [System.Collections.Generic.List[string]]::new()
    $pathsToScan = @("C:\Users")

    foreach ($path in $pathsToScan) {
        if (Test-Path $path) {
            # Se excluyen carpetas de sistema profundas para no demorar horas
            $files = Get-ChildItem -Path $path -Recurse -File -Include "*.jar","*.exe","*.dll" -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -match "clicker|autoclick|ghost|meteor|wurst|aristois|vape|raven|krypton|totem"
            }
            foreach ($f in $files) {
                Write-Host "     [!] Hack Oculto: $($f.Name)" -ForegroundColor Red
                Write-Host "         Ruta: $($f.FullName)" -ForegroundColor Yellow
                $hallazgosDisco.Add($f.Name)
            }
        }
    }

    Show-DetectionBox -Detections $hallazgosDisco -Title "ARCHIVOS SOSPECHOSOS EN EL DISCO"
    Pause-Scanner
}

# ============================================================
# MENÚ PRINCIPAL (BLINDADO CON TRY/CATCH GLOBAL)
# ============================================================
function Show-MainMenu {
    while ($true) {
        try {
            Show-Banner
            Write-Host "     ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkRed
            Write-Host "     ║               MODO: INTERVENCIÓN Y AUDITORÍA                 ║" -ForegroundColor White
            Write-Host "     ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkRed
            Write-Host "`n       [1] Analizar Mods (.minecraft\mods)       [7] Servicios Windows (Omitido)" -ForegroundColor White
            Write-Host "       [2] Detección Profunda Hacks                [8] Análisis DLLs (Omitido)" -ForegroundColor Yellow
            Write-Host "       [3] Intervención Rápida (Prefetch Hoy)      [9] Ver Hallazgos (Omitido)" -ForegroundColor White
            Write-Host "       [4] Análisis Papelera (Omitido)            [10] Auditoría Macros (Omitido)" -ForegroundColor White
            Write-Host "       [5] Killer Screen (Omitido)                [11] Análisis Completo del Disco" -ForegroundColor Cyan
            Write-Host "                                                  [12] Salir de la Aplicación" -ForegroundColor Red
            Write-Host "`n     ----------------------------------------------------------------" -ForegroundColor DarkGray
            
            $option = Read-Host "`n     Selecciona una opción [1-12]"
            switch ($option) {
                "1" { Start-FullModScan }
                "2" { Start-DoomsdayMemoryScan }
                "3" { Start-SystemScan }
                "11"{ Start-FullDiskScan }
                "12"{ Clear-Host; Write-Host "`n     ¡Hasta luego, Joaquín!`n" -ForegroundColor Red; return }
                default { Write-Host "`n     [!] Opción en construcción o inválida." -ForegroundColor Red; Start-Sleep -Seconds 1 }
            }
        } catch {
            Write-Host "`n     [!] Protección activada. El script evitó un cierre inesperado." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}

# Iniciar aplicación
Show-MainMenu
