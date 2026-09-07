#Requires -Version 5.1
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================
# EL SOMBRIO IF - FORENSIC SCANNER (MASTER ENGINE 2026)
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
$script:BamPcaTable       = [System.Collections.Generic.List[PSCustomObject]]::new()
$script:DllModTable       = [System.Collections.Generic.List[PSCustomObject]]::new()
$script:WindowsServices   = @("dps", "appinfo", "pcasvc", "eventlog", "sysmain", "dusmsvc", "bam")

# ============================================================
# NTLD DECOMPRESSOR & MOTOR DOOMSDAY (DE TU CÓDIGO BASE)
# ============================================================
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

function Show-Banner {
    $duck1 = @"
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡏⠉⢻⣷⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣿⣾⣿⣿⣶⣶⣶⣦⣤⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⠏⠉⠉⠉⠁⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⠿⠟⠀⠀⠀⠀⠀⠀⠀⠀
"@
    $duck2 = @"
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣤⣤⣤⣤⣤⣶⣾⣷⣄⠀⠀⠀⠀⠀
⠀⠀⣶⣤⣤⣤⣤⣤⣤⣶⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⠛⢻⣿⣿⣿⡆⠀⠀⠀⠀
⠀⠀⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⢀⣿⣿⣿⣿⡇⠀⠀⠀⠀
⠀⠀⠈⢿⣿⣿⣏⡈⠛⠿⠿⣿⣿⣿⠿⠿⠟⠋⣁⣴⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀
⠀⠀⠀⠀⠙⠿⣿⣿⣶⣦⣤⣤⣤⣤⣤⣴⣶⣿⣿⣿⣿⣿⣿⡿⠏⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠈⠙⠛⠻⠿⠿⠿⢿⡿⠿⠿⠿⠟⠛⠉⠁⠀⠀⠀⠀⠀⠀⠀
"@
    $duck3 = @"
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⡄⢠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⣧⣾⣶⣤⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠉⠉⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
"@

    Write-Host $duck1 -ForegroundColor Yellow
    Write-Host $duck2 -ForegroundColor White
    Write-Host $duck3 -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "                    Made by " -NoNewline
    Write-Host "zedoon (aka Yaz) " -NoNewline -ForegroundColor White
    Write-Host "@" -NoNewline -ForegroundColor Blue
    Write-Host " Mars MC SS team " -NoNewline -ForegroundColor Yellow
    Write-Host "&" -NoNewline -ForegroundColor Blue
    Write-Host " RL forensics" -ForegroundColor Red
    Write-Host ""
    Write-Host "                    Doomsday Client Scanner v1.2 (USN Journal)" -ForegroundColor Cyan
    Write-Host ""
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-PrefetchVersion {
    param([byte[]]$data)
    if ($data.Length -lt 8) { return 0 }
    $sig = [System.Text.Encoding]::ASCII.GetString($data, 4, 4)
    if ($sig -ne "SCCA") { return 0 }
    return [BitConverter]::ToUInt32($data, 0)
}

function Get-SystemIndexes {
    param([string]$FilePath)
    try {
        $data = [System.IO.File]::ReadAllBytes($FilePath)
        $isCompressed = ($data[0] -eq 0x4D -and $data[1] -eq 0x41 -and $data[2] -eq 0x4D)
        if ($isCompressed) {
            $data = [NtdllDecompressor]::Decompress($data)
            if ($data -eq $null) { return @() }
        }
        if ($data.Length -lt 108) { return @() }
        
        $stringsOffset = [BitConverter]::ToUInt32($data, 100)
        $stringsSize = [BitConverter]::ToUInt32($data, 104)
        if ($stringsOffset -eq 0 -or $stringsSize -eq 0 -or ($stringsOffset + $stringsSize) -gt $data.Length) { return @() }
        
        $filenames = @()
        $pos = $stringsOffset
        $endPos = $stringsOffset + $stringsSize
        while ($pos -lt $endPos -and $pos -lt $data.Length - 2) {
            $nullPos = $pos
            while ($nullPos -lt $data.Length - 1) {
                if ($data[$nullPos] -eq 0 -and $data[$nullPos + 1] -eq 0) { break }
                $nullPos += 2
            }
            if ($nullPos -gt $pos) {
                try {
                    $filename = [System.Text.Encoding]::Unicode.GetString($data, $pos, ($nullPos - $pos))
                    if ($filename.Length -gt 0) { $filenames += $filename }
                } catch {}
            }
            $pos = $nullPos + 2
            if ($filenames.Count -gt 1000) { break }
        }
        return $filenames
    } catch { return @() }
}

$script:BytePatterns = @(
    @{ Name = "Pattern #1"; Bytes = "6161370E160609949E0029033EA7000A2C1D03548403011D1008A1FFF6033EA7000A2B1D03548403011D07A1FFF710FEAC150599001A2A160C14005C6588B800" },
    @{ Name = "Pattern #2"; Bytes = "0C1504851D85160A6161370E160609949E0029033EA7000A2C1D03548403011D1008A1FFF6033EA7000A2B1D03548403011D07A1FFF710FEAC150599001A2A16" },
    @{ Name = "Pattern #3"; Bytes = "5910071088544C2A2BB8004D3B033DA7000A2B1C03548402011C1008A1FFF61A9E000C1A110800A2000503AC04AC00000000000A0005004E000101FA000001D3" }
)

$script:ClassPatterns = @("net/java/f", "net/java/g", "net/java/h", "net/java/i", "net/java/k", "net/java/l", "net/java/m", "net/java/r", "net/java/s", "net/java/t", "net/java/y")

function ConvertHex-ToBytes {
    param([string]$hexString)
    $bytes = New-Object byte[] ($hexString.Length / 2)
    for ($i = 0; $i -lt $hexString.Length; $i += 2) {
        $bytes[$i / 2] = [Convert]::ToByte($hexString.Substring($i, 2), 16)
    }
    return $bytes
}

function Search-BytePattern {
    param([byte[]]$data, [byte[]]$pattern)
    for ($i = 0; $i -le ($data.Length - $pattern.Length); $i++) {
        $match = $true
        for ($j = 0; $j -lt $pattern.Length; $j++) {
            if ($data[$i + $j] -ne $pattern[$j]) { $match = $false; break }
        }
        if ($match) { return $true }
    }
    return $false
}

function Test-DoomsdayClient {
    param([string]$Path)
    $result = [PSCustomObject]@{ IsDetected = $false; Confidence = "NONE" }
    if (-not (Test-Path $Path)) { return $result }
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $jar = [System.IO.Compression.ZipFile]::OpenRead($Path)
        $classFiles = $jar.Entries | Where-Object { $_.FullName -like "*.class" }
        if ($classFiles.Count -eq 0 -or $classFiles.Count -gt 30) { $jar.Dispose(); return $result }
        
        $allBytes = @()
        foreach ($entry in $classFiles) {
            $stream = $entry.Open()
            $reader = New-Object System.IO.BinaryReader($stream)
            $allBytes += $reader.ReadBytes([int]$entry.Length)
            $reader.Close(); $stream.Close()
        }
        $jar.Dispose()

        $matches = 0
        foreach ($pattern in $script:BytePatterns) {
            if (Search-BytePattern -data $allBytes -pattern (ConvertHex-ToBytes $pattern.Bytes)) { $matches++ }
        }
        if ($matches -ge 1) {
            $result.IsDetected = $true
            $result.Confidence = if ($matches -ge 2) { "HIGH" } else { "MEDIUM" }
        }
    } catch {}
    return $result
}

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

# ============================================================
# MÓDULO 1: ANÁLISIS DE MODS (RESUMEN ILEGAL AL FINAL)
# ============================================================
function Start-FullModScan {
    Show-Header "ANÁLISIS GENERAL DE MODS (.MINECRAFT\MODS)"
    $modsPath = Read-Host "     Ruta de la carpeta de mods [$($script:DefaultModsPath)]"
    if ([string]::IsNullOrWhiteSpace($modsPath)) { $modsPath = $script:DefaultModsPath }

    if (-not (Test-Path -LiteralPath $modsPath)) {
        Write-Host "`n     [!] La carpeta de mods no existe." -ForegroundColor Red
        Pause-Scanner; return
    }

    $filesInFolder = @(Get-ChildItem -LiteralPath $modsPath -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
    if ($filesInFolder.Count -eq 0) {
        Write-Host "`n     [!] No se encontraron archivos en la carpeta." -ForegroundColor Yellow
        Pause-Scanner; return
    }

    $javaProc = Get-Process -Name "javaw", "java" -ErrorAction SilentlyContinue
    if ($javaProc) {
        Write-Host "`n     [i] Estado del Juego: Ejecutándose (Instancia Activa)" -ForegroundColor Green
    } else {
        Write-Host "`n     [i] Estado del Juego: Cerrado" -ForegroundColor Yellow
    }

    Write-Host "     [*] Analizando mods y ordenando por fecha reciente..." -ForegroundColor White
    Write-Host ""

    $total = $filesInFolder.Count
    $current = 0
    $resultadosTemp = [System.Collections.Generic.List[PSCustomObject]]::new()
    $modsIlegalesEncontrados = [System.Collections.Generic.List[string]]::new()

    foreach ($file in $filesInFolder) {
        $current++
        $percent = [math]::Floor(($current / $total) * 100)
        $blocks = [math]::Floor($percent / 5)
        $bar = ("█" * $blocks) + ("░" * (20 - $blocks))
        Write-Host -NoNewline "`r     [$bar] $percent% ($current/$total)" -ForegroundColor Cyan

        $name = $file.BaseName.ToLower() -replace '[\s\-_]', ''
        $status = "Legítimo"
        $isIllegal = $false

        foreach ($kw in $script:IllegalKeywords) {
            $cleanKw = $kw -replace '[\s\-_]', ''
            if ($name -like "*$cleanKw*") { $isIllegal = $true; $status = "¡HACK / ILEGAL!"; break }
        }

        if (-not $isIllegal -and $file.Extension.ToLower() -eq ".jar") {
            $doomsdayRes = Test-DoomsdayClient -Path $file.FullName
            if ($doomsdayRes.IsDetected) {
                $isIllegal = $true
                $status = "¡DOOMSDAY CLIENT!"
            }
        }

        if ($isIllegal) {
            $modsIlegalesEncontrados.Add($file.Name)
        }

        $enInstancia = if ($javaProc) { "Ejecutándose (Cargado)" } else { "Cerrado" }
        $resultadosTemp.Add([PSCustomObject]@{
            Nombre = $file.Name
            Estado = $status
            Instancia = $enInstancia
            RawDate = $file.LastWriteTime
            Fecha = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            Ilegal = $isIllegal
        })
    }

    Write-Host "`n`n     [✔] ¡Análisis de mods completado!" -ForegroundColor Green
    Write-Host "     ----------------------------------------------------------------" -ForegroundColor DarkGray

    foreach ($res in ($resultadosTemp | Sort-Object RawDate -Descending)) {
        if ($res.Ilegal) {
            Write-Host "     [X] $($res.Nombre) --> $($res.Estado) | Instancia: $($res.Instancia) | Fecha: $($res.Fecha)" -ForegroundColor Red
        } else {
            Write-Host "     [+] $($res.Nombre) --> $($res.Estado) | Instancia: $($res.Instancia) | Fecha: $($res.Fecha)" -ForegroundColor Green
        }
    }

    if ($modsIlegalesEncontrados.Count -gt 0) {
        Write-Host ""
        Write-Host "     ================================================================" -ForegroundColor Red
        Write-Host "     [!] RESUMEN DE MODS ILEGALES DETECTADOS:" -ForegroundColor Red
        foreach ($modIllegal in $modsIlegalesEncontrados) {
            Write-Host "         - $modIllegal" -ForegroundColor Red
        }
        Write-Host "     ================================================================" -ForegroundColor Red
    }

    Pause-Scanner
}

# ============================================================
# MÓDULO 2: DETECCIÓN PROFUNDA DOOMSDAY (CON TU CÓDIGO BASE INTEGRADO)
# ============================================================
function Start-DoomsdayMemoryScan {
    Show-Banner
    if (-not (Test-Administrator)) {
        Write-Host "     [!] Se requiere Administrador." -ForegroundColor Yellow
        Pause-Scanner; return
    }

    Write-Host "     [*] Analizando prefetch de Java con motor Doomsday v1.2..." -ForegroundColor Cyan
    $systemPath = "C:\Windows\Prefetch"
    if (-not (Test-Path $systemPath)) {
        Write-Host "     [!] Directorio Prefetch no encontrado." -ForegroundColor Red
        Pause-Scanner; return
    }

    $javaFiles = Get-ChildItem -Path $systemPath -Filter "JAVA*.EXE-*.pf" -ErrorAction SilentlyContinue
    if ($javaFiles.Count -eq 0) {
        Write-Host "     [!] No se encontraron archivos Prefetch de Java." -ForegroundColor Yellow
        Pause-Scanner; return
    }

    $totalDetections = 0
    foreach ($sysFile in $javaFiles) {
        $indexes = Get-SystemIndexes -FilePath $sysFile.FullName
        foreach ($index in $indexes) {
            if ($index -match '\.jar$') {
                $checkPath = $index
                if ($index -match '\\VOLUME\{[^\}]+\}\\(.*)$') { $checkPath = "C:\$($Matches[1])" }
                
                if (Test-Path $checkPath) {
                    $res = Test-DoomsdayClient -Path $checkPath
                    if ($res.IsDetected) {
                        $totalDetections++
                        Write-Host "     [X] ¡DOOMSDAY DETECTADO! Archivo: $checkPath [Confianza: $($res.Confidence)]" -ForegroundColor Red
                    }
                }
            }
        }
    }

    if ($totalDetections -eq 0) {
        Write-Host "     [+] No se detectó Doomsday Client en los rastros analizados." -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "     [X] ¡DOOMSDAY CLIENT CONFIRMADO! Proceder con baneo por Hacks in SS." -ForegroundColor Red
    }

    Pause-Scanner
}

# ============================================================
# MÓDULO 3: INTERVENCIÓN RÁPIDA (PREFETCH DE HOY CON AUTOCLICK Y JAVA)
# ============================================================
function Start-SystemScan {
    Show-Header "INTERVENCIÓN RÁPIDA (PREFETCH DE HOY 07/09/2026)"
    if (-not (Test-Administrator)) { Write-Host "     [!] Se requieren privilegios de Administrador." -ForegroundColor Yellow; Pause-Scanner; return }

    $todayStr = "2026-09-07"
    Write-Host "     [*] Analizando registros Prefetch correspondientes al día de hoy ($todayStr)..." -ForegroundColor Cyan
    Write-Host ""

    $prefetchPath = "C:\Windows\Prefetch"
    if (Test-Path $prefetchPath) {
        $pfFiles = @(Get-ChildItem -Path $prefetchPath -Filter "*.pf" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
        
        $encontradosHoy = 0
        foreach ($pf in $pfFiles) {
            $fileDateStr = $pf.LastWriteTime.ToString("yyyy-MM-dd")
            if ($fileDateStr -eq $todayStr) {
                $encontradosHoy++
                $pfNameLower = $pf.Name.ToLower()

                if ($pfNameLower -match "click|autoclick|macro|jclicker|ghostclicker") {
                    Write-Host "     [!] [AUTOCLICK / HACK DETECTADO] $($pf.Name) | Fecha: $($pf.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"))" -ForegroundColor Red
                }
                elseif ($pfNameLower -like "*java*") {
                    Write-Host "     [+] [JAVA EJECUTADO] $($pf.Name) | Fecha: $($pf.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"))" -ForegroundColor Green
                }
                else {
                    Write-Host "     [i] [PROCESO] $($pf.Name) | Fecha: $($pf.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"))" -ForegroundColor Gray
                }
            }
        }

        if ($encontradosHoy -eq 0) {
            Write-Host "     [i] No se registraron ejecuciones en el Prefetch para la fecha de hoy ($todayStr)." -ForegroundColor Yellow
        }
    }

    Pause-Scanner
}

# ============================================================
# MÓDULO 4: PAPELERA DE RECICLAJE
# ============================================================
function Start-RecycleBinScan {
    Show-Header "ANÁLISIS DE PAPELERA DE RECICLAJE"
    Write-Host "     [*] Buscando archivos eliminados..." -ForegroundColor White
    
    $script:RecycleBinTable.Clear()
    try {
        $shell = New-Object -ComObject Shell.Application
        $recycleBin = $shell.NameSpace(10)
        foreach ($item in $recycleBin.Items()) {
            $fechaElim = $recycleBin.GetDetailsOf($item, 2)
            $script:RecycleBinTable.Add([PSCustomObject]@{
                Archivo = $item.Name
                RutaOriginal = $recycleBin.GetDetailsOf($item, 1)
                FechaEliminacion = if ([string]::IsNullOrEmpty($fechaElim)) { "No disponible" } else { $fechaElim }
                Estado = "Eliminado (En Papelera)"
            })
            Write-Host "     [!] Papelera: $($item.Name) | Fecha: $fechaElim" -ForegroundColor Red
        }
    } catch {}

    if ($script:RecycleBinTable.Count -eq 0) {
        Write-Host "     [+] La Papelera de Reciclaje está limpia." -ForegroundColor Green
    }
    Pause-Scanner
}

# ============================================================
# MÓDULO 5: AUDITORÍA DE MACROS
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
# MÓDULO 6: KILLER SCREEN PROCESSES (DIFF)
# ============================================================
function Start-DiffKiller {
    Show-Header "FINALIZADOR DE PROCESOS (DIFF)"
    $forbidden = @("obs","obs32","obs64","discord","streamlabs","bandicam","sharex","gamebar")
    $detected = @()
    foreach ($proc in Get-Process -ErrorAction SilentlyContinue) {
        if ($forbidden -contains $proc.Name.ToLower()) {
            $detected += $proc.Name
            Write-Host "     [!] Proceso detectado: $($proc.Name) [Ejecutándose]" -ForegroundColor Green
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
# MÓDULO 8: ANÁLISIS DE DLLs MODIFICADAS
# ============================================================
function Start-DllScan {
    Show-Header "ANÁLISIS DE DLLs MODIFICADAS (SYSTEM32 / SYSWOW64)"
    if (-not (Test-Administrator)) { Write-Host "     [!] Se requiere Administrador." -ForegroundColor Yellow; Pause-Scanner; return }

    Write-Host "     [*] Analizando DLLs del sistema y ordenando por fecha reciente..." -ForegroundColor White
    $systemPaths = @("$env:SystemRoot\System32", "$env:SystemRoot\SysWOW64")
    $script:DllModTable.Clear()

    foreach ($path in $systemPaths) {
        if (-not (Test-Path $path)) { continue }
        $dllFiles = @(Get-ChildItem -Path $path -Filter "*.dll" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
        foreach ($file in $dllFiles) {
            try {
                $sig = Get-AuthenticodeSignature $file.FullName -ErrorAction SilentlyContinue
                if ($sig.Status -ne 'Valid') {
                    $script:DllModTable.Add([PSCustomObject]@{
                        Archivo = $file.Name
                        EstadoFirma = $sig.Status
                        RawDate = $file.LastWriteTime
                        UltimaModificacion = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                        Ruta = $file.FullName
                    })
                }
            } catch {}
        }
    }

    if ($script:DllModTable.Count -eq 0) {
        Write-Host "     [+] No se encontraron DLLs modificadas o sin firma válida." -ForegroundColor Green
    } else {
        foreach ($dll in ($script:DllModTable | Sort-Object RawDate -Descending)) {
            Write-Host "     [!] DLL Anómala: $($dll.Archivo) | Fecha: $($dll.UltimaModificacion)" -ForegroundColor Red
        }
    }
    Pause-Scanner
}

# ============================================================
# TABLA DE HALLAZGOS Y EJECUCIONES
# ============================================================
function Show-InformationTable {
    Show-Header "REGISTRO DE EJECUCIONES Y HALLAZGOS (MÁS RECIENTE ARRIBA)"

    Write-Host "     [ 1 ] PAPELERA / DLLs ANÓMALAS" -ForegroundColor White
    Write-Host "     ----------------------------------------------------------------" -ForegroundColor DarkGray
    foreach ($rec in $script:RecycleBinTable) {
        Write-Host "     [!] PAPELERA | $($rec.Archivo) | Fecha: $($rec.FechaEliminacion)" -ForegroundColor Red
    }
    foreach ($dll in ($script:DllModTable | Sort-Object RawDate -Descending)) {
        Write-Host "     [!] DLL MODIFICADA | $($dll.Archivo) | Fecha: $($dll.UltimaModificacion)" -ForegroundColor Red
    }
    Pause-Scanner
}

# ============================================================
# MENÚ PRINCIPAL
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
        Write-Host "       [1] Analizar Mods (.minecraft\mods)       [4] Análisis Papelera de Reciclaje" -ForegroundColor White
        Write-Host "       [2] Detección Profunda Doomsday             [5] Auditoría de Macros" -ForegroundColor Yellow
        Write-Host "       [3] Intervención Rápida (Prefetch Hoy)      [6] Killer Screen (Diff)" -ForegroundColor White
        Write-Host "       [7] Servicios Windows                       [8] Análisis DLLs Modificadas" -ForegroundColor White
        Write-Host "       [9] Ver Hallazgos / Tablas                 [10] Salir de la Aplicación" -ForegroundColor Red
        Write-Host ""
        Write-Host "     ----------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
        
        $option = Read-Host "     Selecciona una opción [1-10]"
        switch ($option) {
            "1" { Start-FullModScan }
            "2" { Start-DoomsdayMemoryScan }
            "3" { Start-SystemScan }
            "4" { Start-RecycleBinScan }
            "5" { Start-MacroAudit }
            "6" { Start-DiffKiller }
            "7" { Show-WindowsServices }
            "8" { Start-DllScan }
            "9" { Show-InformationTable }
            "10" { Clear-Host; Write-Host "`n     ¡Hasta luego, Joaquín!`n" -ForegroundColor Red; return }
            default { Write-Host "`n     [!] Opción no válida." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

Show-MainMenu
