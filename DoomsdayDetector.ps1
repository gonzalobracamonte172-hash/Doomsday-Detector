#Requires -Version 5.1
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================
# EL SOMBRIO IF - FORENSIC SCANNER (MASTER OPTIMIZADO 2026)
# ============================================================

$script:DefaultModsPath = "$env:APPDATA\.minecraft\mods"

$script:IllegalKeywords = @(
    "antighosttotem", "fasttotem", "totemhelper", "autototem", "switchtotems",
    "acurateblock", "fastplace", "attacktroughgrass", "periodicattack", "toroautoattack",
    "maceattack", "autoclicker", "autoclick", "clicker", "macros", "freecam",
    "tweakeroo", "inventorynext", "hotbaroptimizer", "fastxp", "slotcycler",
    "quickhotkeys", "itemscroller", "autoswitch", "xray",
    "nojumpdelay", "noinputlag", "nohitdelay", "elytrabugfix", "firerocketkey",
    "marrowcrystal", "anchoroptimizer", "quickelytra", "clickcrystals",
    "radarbro", "zansmap", "voxelmap", "xaerosmap",
    "aimbot", "killaura", "reach", "fly", "scaffold", "criticals", "jclicker", "ghostclicker",
    "doomsday", "jnativehook"
)

$script:FoundItemsTable   = [System.Collections.Generic.List[PSCustomObject]]::new()
$script:JavaPrefetchTable = [System.Collections.Generic.List[PSCustomObject]]::new()
$script:RecycleBinTable   = [System.Collections.Generic.List[PSCustomObject]]::new()
$script:MacroCheckTable   = [System.Collections.Generic.List[PSCustomObject]]::new()
$script:WindowsServices   = @("dps", "appinfo", "pcasvc", "eventlog", "sysmain", "dusmsvc", "bam")

# ============================================================
# MOTOR NTLD DECOMPRESSOR
# ============================================================
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
            if (compressed.Length < 8) return null;
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
                uint status = RtlDecompressBufferEx(4, result, uncompSize, compData, compData.Length, out finalSize, workspace);
                if (status != 0) return null;
                return result;
            }
            finally { Marshal.FreeHGlobal(workspace); }
        }
    }
"@
} catch { }

# ============================================================
# INTERFAZ Y CENTRADO
# ============================================================

function Get-CenteredText {
    param([string]$Text, [int]$Width = 62)
    if ($Text.Length -ge $Width) { return $Text.Substring(0, $Width) }
    $padding = [math]::Floor(($Width - $Text.Length) / 2)
    return (' ' * $padding) + $Text
}

function Show-Header {
    param([string]$Subtitle)
    Clear-Host
    Write-Host ""
    Write-Host "     ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkRed
    Write-Host "     ║               EL SOMBRIO IF - FORENSIC SCANNER               ║" -ForegroundColor Red
    Write-Host "     ╠══════════════════════════════════════════════════════════════╣" -ForegroundColor DarkRed
    Write-Host ("     ║{0,-62}║" -f (Get-CenteredText $Subtitle)) -ForegroundColor White
    Write-Host "     ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkRed
    Write-Host ""
}

function Pause-Scanner {
    Write-Host ""
    Write-Host "     [ Presiona ENTER para regresar al menú principal ]" -ForegroundColor DarkGray
    Read-Host | Out-Null
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Reset-ScanInfo {
    $script:FoundItemsTable.Clear()
    $script:JavaPrefetchTable.Clear()
    $script:RecycleBinTable.Clear()
    $script:MacroCheckTable.Clear()
}

function Test-DoomsdayJar {
    param([string]$Path)
    try {
        $data = [System.IO.File]::ReadAllBytes($Path)
        $isComp = ($data[0] -eq 0x4D -and $data[1] -eq 0x41 -and $data[2] -eq 0x4D)
        if ($isComp) { $data = [NtdllDecompressor]::Decompress($data); if (-not $data) { return $false } }
    } catch { return $false }

    $text = [System.Text.Encoding]::ASCII.GetString($data)
    foreach ($class in @("net/java/f", "net/java/g", "net/java/h", "net/java/i", "net/java/k", "net/java/l", "net/java/m", "net/java/r", "net/java/s", "net/java/t", "net/java/y")) {
        if ($text.Contains($class)) { return $true }
    }
    return $false
}

# ============================================================
# MÓDULO 1: ANÁLISIS DE MODS
# ============================================================
function Start-FullModScan {
    Show-Header "ANÁLISIS GENERAL DE MODS (.MINECRAFT\MODS)"
    $modsPath = Read-Host "     Ruta de la carpeta de mods [$($script:DefaultModsPath)]"
    if ([string]::IsNullOrWhiteSpace($modsPath)) { $modsPath = $script:DefaultModsPath }

    if (-not (Test-Path -LiteralPath $modsPath)) {
        Write-Host "`n     [!] La carpeta de mods no existe." -ForegroundColor Red
        Pause-Scanner; return
    }

    $filesInFolder = @(Get-ChildItem -LiteralPath $modsPath -File -ErrorAction SilentlyContinue)
    $javaProc = Get-Process -Name "javaw", "java" -ErrorAction SilentlyContinue
    $minecraftAbierto = [bool]$javaProc
    $instanciaInfo = if ($minecraftAbierto) { "Abierto (Instancia Activa)" } else { "Cerrado" }

    Write-Host "`n     [i] Estado del Juego: $instanciaInfo" -ForegroundColor $(if ($minecraftAbierto) { "Green" } else { "Yellow" })
    Write-Host "     [*] Analizando mods instantáneamente..." -ForegroundColor White
    Write-Host ""

    foreach ($file in $filesInFolder) {
        $name = $file.BaseName.ToLower() -replace '[\s\-_]', ''
        $status = "Legítimo"
        $isIllegal = $false

        foreach ($kw in $script:IllegalKeywords) {
            $cleanKw = $kw -replace '[\s\-_]', ''
            if ($name -like "*$cleanKw*") { $isIllegal = $true; $status = "¡HACK / ILEGAL!"; break }
        }

        if (-not $isIllegal -and $file.Extension.ToLower() -eq ".jar" -and (Test-DoomsdayJar -Path $file.FullName)) {
            $isIllegal = $true
            $status = "¡DOOMSDAY CLIENT!"
        }

        $enInstancia = if ($minecraftAbierto) { "Cargado" } else { "Cerrado" }

        if ($isIllegal) {
            Write-Host "     [X] $($file.Name) --> $status | Instancia: $enInstancia" -ForegroundColor Red
        } else {
            Write-Host "     [+] $($file.Name) --> $status | Instancia: $enInstancia" -ForegroundColor Green
        }
    }
    Pause-Scanner
}

# ============================================================
# MÓDULO 2: INTERVENCIÓN RÁPIDA (PREFETCH CON HORA EXPLÍCITA)
# ============================================================
function Start-SystemScan {
    Show-Header "INTERVENCIÓN RÁPIDA (PREFETCH & ZONAS CLAVE)"
    if (-not (Test-Administrator)) { Write-Host "     [!] Se requiere Administrador." -ForegroundColor Yellow; Pause-Scanner; return }

    $prefetchPath = "C:\Windows\Prefetch"
    if (Test-Path $prefetchPath) {
        Write-Host "     [*] Analizando registros Prefetch con hora exacta..." -ForegroundColor White
        $pfFiles = @(Get-ChildItem -Path $prefetchPath -Filter "*.pf" -ErrorAction SilentlyContinue)
        
        $script:JavaPrefetchTable.Clear()
        foreach ($pf in $pfFiles) {
            $pfNameLower = $pf.Name.ToLower() -replace '[\s\-_]', ''
            $lastRunTime = $pf.LastWriteTime

            if ($pfNameLower -like "*java*") {
                $entry = [PSCustomObject]@{ 
                    Proceso = $pf.Name 
                    FechaHoraEjecucion = $lastRunTime.ToString("yyyy-MM-dd HH:mm:ss")
                    Estado = "Cerrado / Inactivo"
                    Tipo = "JAVA / JAVAW" 
                }
                $script:JavaPrefetchTable.Add($entry)
                Write-Host "     [+] Detectado: $($pf.Name) | Hora: $($entry.FechaHoraEjecucion)" -ForegroundColor Cyan
            }

            foreach ($kw in $script:IllegalKeywords) {
                if ($pfNameLower -like "*$kw*") {
                    $script:FoundItemsTable.Add([PSCustomObject]@{ 
                        Tipo = "Prefetch"
                        Elemento = $pf.Name 
                        Categoria = "EJECUTADO (HACK)" 
                        FechaHora = $lastRunTime.ToString("yyyy-MM-dd HH:mm:ss")
                        Estado = "Ejecutado y Cerrado"
                    })
                    break
                }
            }
        }
        Write-Host "`n     [✔] Prefetch procesado correctamente." -ForegroundColor Green
    }
    Pause-Scanner
}

# ============================================================
# MÓDULO 3: PAPELERA DE RECICLAJE
# ============================================================
function Start-RecycleBinScan {
    Show-Header "ANÁLISIS DE PAPELERA DE RECICLAJE"
    Write-Host "     [*] Buscando archivos eliminados..." -ForegroundColor White
    
    $script:RecycleBinTable.Clear()
    try {
        $shell = New-Object -ComObject Shell.Application
        $recycleBin = $shell.NameSpace(10)
        foreach ($item in $recycleBin.Items()) {
            $script:RecycleBinTable.Add([PSCustomObject]@{
                Archivo = $item.Name
                RutaOriginal = $recycleBin.GetDetailsOf($item, 1)
                FechaEliminacion = $recycleBin.GetDetailsOf($item, 2)
                Estado = "Eliminado (En Papelera)"
            })
            Write-Host "     [!] Papelera: $($item.Name) | Fecha: $($recycleBin.GetDetailsOf($item, 2))" -ForegroundColor Red
        }
    } catch {}

    if ($script:RecycleBinTable.Count -eq 0) {
        Write-Host "     [+] La Papelera de Reciclaje está limpia." -ForegroundColor Green
    }
    Pause-Scanner
}

# ============================================================
# MÓDULO 4: AUDITORÍA DE MACROS
# ============================================================
function Start-MacroAudit {
    Show-Header "AUDITORÍA DE MACROS Y PERIFÉRICOS"
    Write-Host "     [*] Verificando rutas de software de macros..." -ForegroundColor White

    $userProfile = $env:USERPROFILE
    $pathsToCheck = @(
        @{ Name = "Logitech Gaming Software"; Path = "$userProfile\AppData\Local\Logitech\Logitech Gaming Software\settings.json" },
        @{ Name = "Logitech G HUB"; Path = "$userProfile\AppData\Local\LGHUB\settings.db" },
        @{ Name = "BYCOMBO (MOG601)"; Path = "$userProfile\AppData\BYCOMBO-2\mac" },
        @{ Name = "Blackweb / Asus AP"; Path = "C:\Blackweb Gaming AP\config" },
        @{ Name = "Bloody7 Scripts"; Path = "C:\Program Files (x86)\Bloody7\Bloody7\Data\Mouse\English\ScriptsMacros\GunLib\" },
        @{ Name = "Corsair CUE"; Path = "$userProfile\AppData\Roaming\Corsair\CUE\Config.cuecfg" },
        @{ Name = "Motospeed v60"; Path = "C:\Program Files (x86)\MotoSpeed Gaming Mouse\V60\modules\Settings" },
        @{ Name = "Razer Synapse Log"; Path = "C:\ProgramData\Razer\Synapse3\Log\SynapseService.log" },
        @{ Name = "Redragon M715"; Path = "$userProfile\Documents\M715 Gaming Mouse\MacroDB" },
        @{ Name = "Redragon M719"; Path = "$userProfile\Documents\INVADER Gaming Mouse\MacroDB" }
    );

    $detectadosCount = 0
    foreach ($item in $pathsToCheck) {
        if (Test-Path $item.Path) {
            $detectadosCount++
            $extraInfo = "Encontrado"
            $alertColor = "Yellow"
            if ($item.Name -eq "Corsair CUE" -and (Get-Content $item.Path -Raw -ErrorAction SilentlyContinue) -match "RecMouseClicksEnable") {
                $extraInfo = "RecMouseClicksEnable Activo"
                $alertColor = "Red"
            }
            Write-Host "     [!] Detectado: $($item.Name) [$extraInfo]" -ForegroundColor $alertColor
        }
    }

    if ($detectadosCount -eq 0) {
        Write-Host "     [+] No se encontraron rastros de macros." -ForegroundColor Green
    }
    Pause-Scanner
}

# ============================================================
# MÓDULO 5: USN JOURNAL
# ============================================================
function Start-UsnJournalScan {
    Show-Header "ANÁLISIS USN JOURNAL (ARCHIVOS ELIMINADOS)"
    if (-not (Test-Administrator)) { Write-Host "     [!] Se requiere Administrador." -ForegroundColor Yellow; Pause-Scanner; return }

    $outputFile = Join-Path $env:USERPROFILE "Desktop\ArchivosEliminados_USN.txt"
    try {
        cmd.exe /c "fsutil usn readjournal c: csv | findstr /i /c:`.jar` /c:`.exe` /c:`.dll` | findstr /i /c:0x80000200 > `"$outputFile`""
        Write-Host "     [✔] Reporte generado en Escritorio." -ForegroundColor Green
        Invoke-Item $outputFile
    } catch {
        Write-Host "     [!] Error al procesar USN." -ForegroundColor Red
    }
    Pause-Scanner
}

# ============================================================
# MÓDULO 6: KILLER SCREEN PROCESSES (DIFF)
# ============================================================
function Start-DiffKiller {
    Show-Header "FINALIZADOR DE PROCESOS (DIFF)"
    $forbidden = @("obs","obs32","obs64","discord","streamlabs","bandicam","sharex","gamobar")
    $detected = @()
    foreach ($proc in Get-Process -ErrorAction SilentlyContinue) {
        if ($forbidden -contains $proc.Name.ToLower()) {
            $detected += $proc.Name
            Write-Host "     [!] Proceso detectado: $($proc.Name)" -ForegroundColor Yellow
        }
    }

    if ($detected.Count -eq 0) {
        Write-Host "     [+] No hay procesos prohibidos activos." -ForegroundColor Green
        Pause-Scanner; return
    }

    Write-Host ""
    $choice = Read-Host "     ¿Cerrar todos los procesos detectados? (S/N)"
    if ($choice.ToUpper() -eq "S") {
        foreach ($name in $detected) {
            Get-Process -Name $name -ErrorAction SilentlyContinue | Stop-Process -Force
            Write-Host "     [Terminado] $name.exe" -ForegroundColor Red
        }
    }
    Pause-Scanner
}

# ============================================================
# MÓDULO 7: SERVICIOS WINDOWS
# ============================================================
function Show-WindowsServices {
    Show-Header "ESTADO DE SERVICIOS WINDOWS (FORENSIC)"
    foreach ($service in $script:WindowsServices) {
        $output = @(& sc.exe query $service 2>&1)
        $text = ($output -join "`n")
        $state = "DESCONOCIDO"; $color = "Gray"

        if ($text -match '(?im)^\s*(ESTADO|STATE)\s*:\s*4\s+RUNNING') {
            $state = "EJECUTÁNDOSE"; $color = "Green"
        } elseif ($text -match '(?im)^\s*(ESTADO|STATE)\s*:\s*1\s+STOPPED') {
            $state = "DETENIDO"; $color = "Yellow"
        } elseif ($text -match '1060') {
            $state = "NO ENCONTRADO"; $color = "Red"
        }
        Write-Host "     - Servicio: $($service.ToUpper()) | Estado: $state" -ForegroundColor $color
    }
    Pause-Scanner
}

# ============================================================
# TABLA DE HALLAZGOS Y EJECUCIONES CON HORA
# ============================================================
function Show-InformationTable {
    Show-Header "REGISTRO DE EJECUCIONES Y HALLAZGOS"

    Write-Host "     [ 1 ] HISTORIAL DE JAVA (PREFETCH)" -ForegroundColor White
    Write-Host "     ----------------------------------------------------------------" -ForegroundColor DarkGray
    if ($script:JavaPrefetchTable.Count -eq 0) {
        Write-Host "     [i] Sin registros recientes." -ForegroundColor Yellow
    } else {
        $script:JavaPrefetchTable | Sort-Object FechaHoraEjecucion -Descending | Format-Table -AutoSize
    }

    Write-Host ""
    Write-Host "     [ 2 ] HACKS / PAPELERA DETECTADOS" -ForegroundColor White
    Write-Host "     ----------------------------------------------------------------" -ForegroundColor DarkGray
    foreach ($item in ($script:FoundItemsTable | Sort-Object FechaHora -Descending)) {
        Write-Host "     [!] $($item.Tipo) | $($item.Elemento) | Fecha: $($item.FechaHora)" -ForegroundColor Red
    }
    foreach ($rec in $script:RecycleBinTable) {
        Write-Host "     [!] PAPELERA | $($rec.Archivo) | Fecha: $($rec.FechaEliminacion)" -ForegroundColor Red
    }
    Pause-Scanner
}

# ============================================================
# MENÚ PRINCIPAL (DISEÑO 1-2-3 ARRIBA / 4-5-6 ABAJO)
# ============================================================
function Show-MainMenu {
    while ($true) {
        Clear-Host
        Write-Host ""
        Write-Host "     ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkRed
        Write-Host "     ║               EL SOMBRIO IF - FORENSIC SCANNER               ║" -ForegroundColor Red
        Write-Host "     ╠══════════════════════════════════════════════════════════════╣" -ForegroundColor DarkRed
        Write-Host "     ║               MODO: INTERVENCIÓN Y AUDITORÍA                 ║" -ForegroundColor White
        Write-Host "     ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkRed
        Write-Host ""
        Write-Host "       [1] Analizar Mods (.minecraft\mods)       [4] Auditoría de Macros" -ForegroundColor White
        Write-Host "       [2] Intervención Rápida (Prefetch)          [5] Killer Screen (Diff)" -ForegroundColor White
        Write-Host "       [3] Análisis Papelera de Reciclaje          [6] Servicios Windows" -ForegroundColor White
        Write-Host "       [7] Ver Hallazgos / Tablas                  [8] Análisis USN Journal" -ForegroundColor White
        Write-Host "       [9] Salir de la Aplicación" -ForegroundColor Red
        Write-Host ""
        Write-Host "     ----------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
        
        $option = Read-Host "     Selecciona una opción [1-9]"
        switch ($option) {
            "1" { Start-FullModScan }
            "2" { Start-SystemScan }
            "3" { Start-RecycleBinScan }
            "4" { Start-MacroAudit }
            "5" { Start-DiffKiller }
            "6" { Show-WindowsServices }
            "7" { Show-InformationTable }
            "8" { Start-UsnJournalScan }
            "9" { Clear-Host; Write-Host "`n     ¡Hasta luego, Joaquín!`n" -ForegroundColor Red; return }
            default { Write-Host "`n     [!] Opción no válida." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

Show-MainMenu