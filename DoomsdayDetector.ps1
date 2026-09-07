#Requires -Version 5.1
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================
# EL SOMBRIO IF - FORENSIC SCANNER (MASTER V3 - SS FORENSIC)
# ============================================================

$script:DefaultModsPath = "$env:APPDATA\.minecraft\mods"

# Base de datos limpia de nombres (Se borró "dooms" y "doomsday" por nombre)
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

# FIRMAS INTERNAS DE BYTES Y CONFIGURACIONES (AQUÍ CAEMOS AL DOOMSDAY OCULTO)
$script:DoomsdayStrings = @(
    "lYgKfQhaCkHofBf", "?WHt4Y", "!hi!kGD@<nS", "%#ksghCP$NIS7$EQuX",
    "jnativehook", "net.java.h", "net.java.r", "net.java.s", "net/java/l", "net/java/n",
    "mod_d", "`"id`":`"dd`"", "`"modid`":`"dd`"", 
    "74b5ddc5-d6b9-4e68-9d1e-d55766c6b282", "53bedd23-02b4-4265-af05-786bb49624cd"
)

$script:WindowsServices = @("dps", "appinfo", "pcasvc", "eventlog", "sysmain", "dusmsvc", "bam")

# ============================================================
# LECTOR DE ARCHIVOS BLINDADO (ANTI-BLOQUEOS DE JAVA)
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

# ============================================================
# MOTOR NTLD DECOMPRESSOR SEGURO
# ============================================================
if (-not ([System.Management.Automation.PSTypeName]'NtdllDecompressor').Type) {
    try {
        Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        public class NtdllDecompressor {
            [DllImport("ntdll.dll")]
            public static extern uint RtlDecompressBufferEx(ushort CompressionFormat, byte[] UncompressedBuffer, int UncompressedBufferSize, byte[] CompressedBuffer, int CompressedBufferSize, out int FinalUncompressedSize, IntPtr WorkSpace);
            [DllImport("ntdll.dll")]
            public static extern uint RtlGetCompressionWorkSpaceSize(ushort CompressionFormat, out uint CompressBufferWorkSpaceSize, out uint CompressFragmentWorkSpaceSize);
            public static byte[] Decompress(byte[] compressed) {
                if (compressed == null || compressed.Length < 8) return null;
                if (compressed[0] != 0x4D || compressed[1] != 0x41 || compressed[2] != 0x4D) return null;
                int uncompSize = BitConverter.ToInt32(compressed, 4);
                uint wsComp, wsFrag;
                if (RtlGetCompressionWorkSpaceSize(4, out wsComp, out wsFrag) != 0) return null;
                IntPtr workspace = Marshal.AllocHGlobal((int)wsFrag);
                byte[] result = new byte[uncompSize];
                try {
                    int finalSize;
                    byte[] compData = new byte[compressed.Length - 8];
                    Array.Copy(compressed, 8, compData, 0, compData.Length);
                    if (RtlDecompressBufferEx(4, result, uncompSize, compData, compData.Length, out finalSize, workspace) != 0) return null;
                    return result;
                } finally { Marshal.FreeHGlobal(workspace); }
            }
        }
"@
    } catch { }
}

# ============================================================
# INTERFAZ Y CUADROS DE DETECCIÓN (BOXES)
# ============================================================
function Show-Banner {
    Clear-Host
    Write-Host "`n                    Made by zedoon (aka Yaz) @ Mars MC SS team & RL forensics" -ForegroundColor Cyan
    Write-Host "                    Doomsday Client Scanner v1.7 (Forensic Config Scanner)" -ForegroundColor Cyan
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
    
    if ($Detections.Count -eq 0) {
        Write-Host "     ║ No se detectaron anomalías en este escaneo.                  ║" -ForegroundColor Green
    } else {
        foreach ($item in $Detections) {
            if ($item.Length -gt 56) { $item = $item.Substring(0, 53) + "..." }
            $itemStr = (" > " + $item).PadRight(60, ' ')
            Write-Host "     ║$itemStr║" -ForegroundColor Yellow
        }
    }
    Write-Host "     ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Red
}

function Test-Administrator {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

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

        # Búsqueda por Nombre (sin doomsday)
        foreach ($kw in $script:IllegalKeywords) {
            if ($name -match $kw) { $isIllegal = $true; $motivo = "Nombre Ilegal ($kw)"; break }
        }

        # Búsqueda Profunda (Bytes inyectados y Archivos de Configuración Internos)
        if (-not $isIllegal -and ($file.Extension -eq ".jar" -or $file.Extension -eq ".zip")) {
            $bytes = Get-SafeBytes -Path $file.FullName
            if ($null -ne $bytes) {
                $contentStr = [System.Text.Encoding]::ASCII.GetString($bytes)
                foreach ($ds in $script:DoomsdayStrings) {
                    if ($contentStr.Contains($ds)) { $isIllegal = $true; $motivo = "Firma Oculta: $ds"; break }
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
    Show-DetectionBox -Detections $hacksEncontrados -Title "RESUMEN DE MODS ILEGALES DETECTADOS"
    Pause-Scanner
}

# ============================================================
# [OPCION 2] DETECCIÓN PROFUNDA (JAVA MEMORY)
# ============================================================
function Start-DoomsdayMemoryScan {
    Show-Header "DETECCIÓN PROFUNDA (HACKS INYECTADOS)"
    Write-Host "     [*] Analizando módulos cargados en los procesos de Java..." -ForegroundColor Cyan
    
    $javaProcs = Get-Process -Name "javaw", "java" -ErrorAction SilentlyContinue
    $inyecciones = [System.Collections.Generic.List[string]]::new()

    if (-not $javaProcs) { Write-Host "`n     [i] No hay procesos de Java en ejecución." -ForegroundColor Yellow } 
    else {
        foreach ($p in $javaProcs) {
            try {
                foreach ($mod in $p.Modules) {
                    $modName = $mod.ModuleName.ToLower()
                    $modPath = $mod.FileName
                    
                    if ($modName -match "jnativehook|meteor|vape") {
                        $inyecciones.Add("Módulo Ilegal: $modName (PID: $($p.Id))")
                        Write-Host "     [X] Inyección interceptada: $modPath" -ForegroundColor Red
                    }
                    elseif ($modPath -match "\.dll$|\.jar$") {
                        $fileInfo = Get-Item $modPath -ErrorAction SilentlyContinue
                        if ($fileInfo -and $fileInfo.Length -lt 25MB) {
                            $bytes = Get-SafeBytes -Path $modPath
                            if ($null -ne $bytes) {
                                $text = [System.Text.Encoding]::ASCII.GetString($bytes)
                                foreach ($ds in $script:DoomsdayStrings) {
                                    if ($text.Contains($ds)) {
                                        $inyecciones.Add("Firma Hack en: $modName")
                                        Write-Host "     [X] Inyección interceptada (Firma): $modPath" -ForegroundColor Red
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {}
        }
    }
    Show-DetectionBox -Detections $inyecciones -Title "INYECCIONES Y HACKS FANTASMA EN JAVA"
    Pause-Scanner
}

# ============================================================
# [OPCION 3] PREFETCH + REGISTRO BAM (MÁS RECIENTE / HOY)
# ============================================================
function Start-SystemScan {
    $todayStr = (Get-Date).ToString("yyyy-MM-dd")
    Show-Header "INTERVENCIÓN RÁPIDA (PREFETCH Y BAM DE HOY $todayStr)"
    if (-not (Test-Administrator)) { Write-Host "     [!] Se requieren privilegios de Administrador para leer BAM."; Pause-Scanner; return }

    $hallazgosAlertas = [System.Collections.Generic.List[string]]::new()

    # 1. LECTURA DE BAM (Background Activity Moderator)
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

    # 2. LECTURA DE PREFETCH
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
                } 
                elseif ($pName -like "*java*") {
                    Write-Host "     [+] [JAVA EJECUTADO] $($pf.Name) | $($pf.LastWriteTime)" -ForegroundColor Green
                } 
                else {
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
            
            if ($item.Name.ToLower() -match "click|macro|ghost|meteor|totem|vape") {
                $hallazgosPapelera.Add("HACK BORRADO: $($item.Name)")
            }
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
                $extraInfo = "MACRO ACTIVA (RecMouseClicks)" 
                $hallazgosMacros.Add("$($item.Name) - Macro Activa")
            } else {
                $hallazgosMacros.Add("$($item.Name) Detectado")
            }
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
# [OPCION 7] SERVICIOS WINDOWS (FORENSIC)
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
            if ($service -eq "pcasvc" -or $service -eq "bam" -or $service -eq "sysmain") {
                $hallazgosSvc.Add("Servicio Crítico Apagado: $service")
            }
        }
        elseif ($text -match '1060') { $state = "NO ENCONTRADO"; $color = "Red" }
        
        Write-Host "     - Servicio: $($service.ToUpper()) | Estado: $state" -ForegroundColor $color
    }

    Show-DetectionBox -Detections $hallazgosSvc -Title "ALERTAS DE SERVICIOS APAGADOS"
    Pause-Scanner
}

# ============================================================
# [OPCION 8] ANÁLISIS DE DLLs MODIFICADAS RECIENTEMENTE
# ============================================================
function Start-DllScan {
    Show-Header "ANÁLISIS DE DLLs DEL SISTEMA MODIFICADAS"
    if (-not (Test-Administrator)) { Write-Host "     [!] Se requiere Administrador."; Pause-Scanner; return }
    
    Write-Host "     [*] Escaneando DLLs alteradas en los últimos 7 días..." -ForegroundColor Cyan
    $limitDate = (Get-Date).AddDays(-7)
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

    Show-DetectionBox -Detections $hallazgosDLL -Title "DLLs ANÓMALAS O SIN FIRMA"
    Pause-Scanner
}

# ============================================================
# [OPCION 11] ANÁLISIS COMPLETO DEL DISCO
# ============================================================
function Start-FullDiskScan {
    Show-Header "ANÁLISIS COMPLETO DEL DISCO (CAZADOR DE HACKS)"
    Write-Host "     [*] Escaneando C:\Users en busca de clientes ocultos..." -ForegroundColor Cyan
    Write-Host "     [i] Por favor espera, esto puede tomar varios minutos.`n" -ForegroundColor DarkGray

    $hallazgosDisco = [System.Collections.Generic.List[string]]::new()
    $pathsToScan = @("C:\Users")

    foreach ($path in $pathsToScan) {
        if (Test-Path $path) {
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
# MENÚ PRINCIPAL
# ============================================================
function Show-MainMenu {
    while ($true) {
        try {
            Show-Banner
            Write-Host "     ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkRed
            Write-Host "     ║               MODO: INTERVENCIÓN Y AUDITORÍA                 ║" -ForegroundColor White
            Write-Host "     ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkRed
            Write-Host "`n       [1] Analizar Mods (.minecraft\mods)       [5] Auditoría de Macros" -ForegroundColor White
            Write-Host "       [2] Detección Profunda Hacks                [6] Killer Screen (Diff)" -ForegroundColor Yellow
            Write-Host "       [3] Intervención Rápida (Prefetch/BAM)      [7] Servicios Windows" -ForegroundColor White
            Write-Host "       [4] Análisis Papelera de Reciclaje         [8] Análisis DLLs Modificadas" -ForegroundColor White
            Write-Host "       --------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "       [11] Análisis Completo del Disco           [12] Salir de la Aplicación" -ForegroundColor Cyan
            Write-Host "`n     ----------------------------------------------------------------" -ForegroundColor DarkGray
            
            $option = Read-Host "`n     Selecciona una opción"
            switch ($option) {
                "1" { Start-FullModScan }
                "2" { Start-DoomsdayMemoryScan }
                "3" { Start-SystemScan }
                "4" { Start-RecycleBinScan }
                "5" { Start-MacroAudit }
                "6" { Start-DiffKiller }
                "7" { Show-WindowsServices }
                "8" { Start-DllScan }
                "11"{ Start-FullDiskScan }
                "12"{ Clear-Host; Write-Host "`n     ¡Hasta luego, Joaquín!`n" -ForegroundColor Red; return }
                default { Write-Host "`n     [!] Opción inválida." -ForegroundColor Red; Start-Sleep -Seconds 1 }
            }
        } catch {
            Write-Host "`n     [!] Protección activada. El script evitó un cierre inesperado." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}

Show-MainMenu
