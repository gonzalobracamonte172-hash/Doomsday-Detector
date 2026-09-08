#Requires -Version 5.1
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================
# EL SOMBRIO IF - FORENSIC SCANNER (MASTER V17 - FURINA EDITION)
# ============================================================

$script:DefaultModsPath = "$env:APPDATA\.minecraft\mods"
$script:FirstRun = $true

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
    "lYgKfQhaCkHofBf", "?WHt4Y", "!hi!kGD@<nS", "%#ksghCP$NIS7$EQuX", "jnativehook"
)

$script:WindowsServices = @("dps", "appinfo", "pcasvc", "eventlog", "sysmain", "dusmsvc", "bam")

# ============================================================
# MOTOR SOMBRIO DECOMPRESSOR SEGURO
# ============================================================
if (-not ([System.Management.Automation.PSTypeName]'SombrioDecompressor').Type) {
    try {
        Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        public class SombrioDecompressor {
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

function Get-SafeBytes {
    param([string]$Path)
    try { $bytes = [System.IO.File]::ReadAllBytes($Path) } 
    catch {
        try {
            $tempFile = "$env:TEMP\sombrio_scan_$([guid]::NewGuid()).tmp"
            Copy-Item -Path $Path -Destination $tempFile -Force -ErrorAction Stop
            $bytes = [System.IO.File]::ReadAllBytes($tempFile)
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        } catch { return $null }
    }
    
    if ($null -ne $bytes -and $bytes.Length -ge 8) {
        if ($bytes[0] -eq 0x4D -and $bytes[1] -eq 0x41 -and $bytes[2] -eq 0x4D) {
            if (([System.Management.Automation.PSTypeName]'SombrioDecompressor').Type) {
                $decomp = [SombrioDecompressor]::Decompress($bytes)
                if ($null -ne $decomp) { return $decomp }
            }
        }
    }
    return $bytes
}

# ============================================================
# ANIMACIONES Y EFECTOS VISUALES
# ============================================================
function Invoke-Typewriter {
    param([string]$Text, [int]$Speed = 15, [string]$Color = "White")
    foreach ($char in $Text.ToCharArray()) {
        Write-Host $char -NoNewline -ForegroundColor $Color
        Start-Sleep -Milliseconds $Speed
    }
    Write-Host ""
}

function Show-BootAnimation {
    # Arte ASCII - Furina
    $furinaAscii = @'
                                                     .::---:               ::
                                                    =-..-::-*=            -+.   -+-
                                                   -: =.     :+          :=+   ===
                                                  :+ .*       =:        ===-::.==.
                                                   -: +                :. ..:. -.=.     ..
                                                    =--=       .....  =:   .=  ==+-   .:++.
                                                     .-==.    =:...::-:    -.   :*-. :==-.
                                                        -=-. .+       :=-     :-: .=:=.+.
                                                          .:=---::::.   -=+:  .  .--.=.
                                                       :----:  ::.  :=:   :=-:   -  :=:::.
                                                     :-.:...::- :- ::::=:  -=.: :-.=-----+
                                                    =. -: :..   . .:    ==  .-.  +-::+.
                                                  --. =.  .   :    =:    *+  -+=:..:=:
                                            :---::. -:  -   :+:  =  =:    ++  .+ ..---
                                             .---::...-.  :-:=  .+   =    .==  --. ..++
                                            ---:.   :. .--..-+  :=    --.   =+.  +.:-:-+
                                            =..: :=--=+-===..-  -..: = :--:.:=-  .=. *+.
                                            *.* -=  *-*..**=  : =..+.=:.   ..=.   .+ :*-
                                            .--.+:  =-*.  .    :--@*=+=:.-=  :=    =:+:+
                                              =:*:-. .+=     .    --.-=:  :-  +    -:=-
                                              :.  ..=-  =-  :::    :-=-    .+=-    --+
                                                   =-..  .-::..::--= ...-:-.-.     ==.
                                                  .=: :. -+:::+-..+..+. -==.      :+
                                                    ::=--=.---+- .-=:=.. ..       :
                                               .:-::--=: :+:.--*--+=. .:=:::
                                              =:-:..:.:.  -..-.... :.:  .  --
                                          .-=-  +=:.=::: .+: .==:=.:-+      =:
                                          =-:. .+ ..  .  .+-:  .-=.=:-     ..+:                   ::
     ==::                              .--     .*  =  -=-.     .:-         :--=+          :-::  ---:  ----+=
    .=::- =--                         --      : +.  --.    .-:::.    .-.      .--  .=:--::. .:-=. ..  :-=:.
   :+:+ -=. -=                .   ::=-        =:.= .  . -=-:.       -= -=       :=.:*-.:    -:-:     :=:---:
   #. *  .*. +              :--+::.        .-:.= +. .=-:==.       .=:   .=-      ::: --*.     =..:-:+=--======
 :-:= .-- +.:--           :-=..*         :=-   +:- -: .-.-       :-.      =-        .=-.      ....      ..-:::
 :-.:=: +.::-::-    ..::-:=:: =:..    ..-: .   --==-..= -.      :=         -+       ++:-:-..  .:-.
  + .-*.:.*::.+:  :*:..     -.:.:-+=::..   +..:. .:.:+  +=     --  ....     =+:.   . ..: *:.--.
  .:---.- =.+. .:: .=.        :.+--       -:  =-::  +. :+-     +.=--:.:+     :=-:::.     .-=.
      ..-.+-+=-:    .+.      .*-+-        +:::..::-.+  :+      --..:  :-      .-::. ....::::::::::=-::::::.
         --.::=::.  -:+   :::.....      ::-:-:==     -=:.=.   :-::-.  .:-        ..:::..          :.-::.  .:-.
        =-..*=-=    -:+ ::.          :--. :=..==     --: .= .-- :=:--::.:=-.                          ..-:   :=
        +.  := :+   ::..            .*  .=- :=+     .+= -:+.:     :=.--.   :--:.                         .=.  --
            :== +=     :.            -:-+:  .::      :: -=+-       :=..--.    .:::::::::::::--==::..      .=. =-
           == +.=-==    --         :-.:=+   =           -==:+   ..::-*   .-::                  .-=.+:       *-=
          =:  =-: ---::  .:     :-=. -:-:..-.         ..==:-::::-:    -.    .-=:.                :++.       +-
          +   -:+:=.=-:-  -.  =-:  .=. :::-=::::::::::.. --: :: :-    .+.      ..-:=.             @:        =
         :=   +.=.= =.-:=.  --: .==:  .+        ..            .= =      +.         ::-=:        .=.       .=
         .=   +.= :-=:-:+.:..  ==:    ==::-:..........::=-:::::--=       +:           -*.       =.        =.
          +:   .=:= -.-=:+   .=-      .+  ........ =:.         --+.       +-           =.     .=        -=
          .*.    :=:=:-:=:  :=        .+::......:::=.:::::::::::=+.       .*:          =      =      .-:.
           .+     .:*--=     -=.      .+  ......  -=.   .   ::.=-+-       := =.        +.    .+    .-.
            .-=     =:.-.     .--:.   .=:-::::::::==:-:::::::::-:-.       =   -.      .=     .=   -:    .:--.
              ::-:   =+ +:       .+    =-         :=           * -=      --    =:     +.      =-  -=    += .-+
                  -   +  :::     -.     +         :=           --=.       =     --   +:        -:  :-:      :*
                  *   :-: *:    +:      -=        :=           .+         +:       --.          :: . .    ::-.
                  .:-.. =.-:   ::        =.       :=           =.        .=       .=.              ::::::::
                    =:=:+.:+  +-       :..*       :+          .+        --       :. =:
                       ..=: +:.      :::  :=      :=          =.     .-:.      -:.   -
                          + :=      =-     =:     :+         -=      +       ..:     *
                         --= .=   --     :-.+.    :+         +      --       -:     .=
                       .=. =- :=...     --  .=    :+        --     .+        .=   .::
                     .=:    =- .+     -=     --   :=        *.:-:..+          * .-..
                  .:-:    .: -: -=  --:       +   :=       --    :-.          *-.
                ::-.    ::-.  +: =-           :+  +.       +                 =-
             .=-.     --.      := +.           .= +.       =.             .:-.
          :--.     .--:.....:.  =- +  .:::      :=:=       .+           -::
      .:=-:.    .--.  ......     =- +..==        .=.+        +         +
      =--::::-=:-.             .:.+ .=.-          -:=        :=       =:
           .=-.         ..::-:::. :+ :=            ++         #=    .+:
          ::-:::::::::::..         -= =:           .+:       .+-: :-:
                                  =--= +:           =:       .+ +:
                                 ::  -: +.          =:       .+  =
                               :+:    +..+          =-       :=  -=
                             .++       + :=         =-       =:   --
                             .-        -* .=.       =-       +     =.
                           .=:          *.  -=      =-      -=      +
                          =-    ..-:-.  +-.:-:      =-      +=:     :-...
                        -+-.::::..      .+: -=+     =-     :+ ==     +=.-= --
                        -:..             .-:=-=-    =:     =   .-:    -..:=.=
                                           :#*..    =:    =-   ..-::.. .  #:
                                             :: --  =:    +    +:  ..:  .=+::
                                            ++*:*:  *.   -=     :*:.:-..=:  :-
                                             .=.::..+    =        .=+-::=   :::
                                              .+.-::+   ==-:.      *:.-:=- .+.+.
                                                +:.-=...+  .+      :.-:.-  :=::
                                              .:+.: ....   :+       --.=.  .+
                                              .:=:-:=:..--*-        =.  .  .+
                                                =+:.....+:.        .*  .  :+:
                                                :.---=-+:          =     -=
                                               -:.::..-=           =...:-.
                                              +-:-*::+-:            ....
                                              :=:::.---:
                                              :+:==:  =-
                                             .:.: .:  -:
                                            :+-     : +:
                                            = --::-:.:=
                                            ==     .=-
                                             :-:::::
'@ -split "`n"

    $bootSteps = @(
        "Inicializando módulos de descompresión NT...",
        "Resolviendo dependencias remotas y APIs...",
        "Inyectando hooks en procesos de memoria...",
        "Sincronizando paleta de colores...",
        "Estableciendo enlace de sistema seguro..."
    )

    # Ciclo de animación flotante
    for ($i=0; $i -lt 15; $i++) {
        Clear-Host
        
        # Efecto de respiración/flote (desplazamiento lateral)
        $floatSpaces = " " * (2 + ($i % 3))
        
        $lineNum = 0
        foreach ($line in $furinaAscii) {
            # Paleta de colores dinámica y estratificada
            if ($lineNum -le 16) { $c = "Cyan" }               # Sombrero y adornos superiores
            elseif ($lineNum -le 25) { $c = "White" }          # Rostro y Piel (Blanco)
            elseif ($lineNum -le 46) { $c = "Blue" }           # Traje y báculo
            elseif ($lineNum -le 54) { $c = "White" }          # Piernas / Piel
            else { $c = "DarkBlue" }                           # Botas y sombras

            Write-Host ($floatSpaces + $line.TrimEnd()) -ForegroundColor $c
            $lineNum++
        }

        # Texto y barra de carga en la parte inferior
        $stepIndex = [math]::Min([math]::Floor($i / 3), $bootSteps.Count - 1)
        Write-Host "`n [Bootloader] $($bootSteps[$stepIndex])" -ForegroundColor Cyan
        
        $pct = [math]::Round((($i + 1) / 15) * 100)
        $barLength = 30
        $filled = [math]::Round(($pct / 100) * $barLength)
        $empty = $barLength - $filled
        $progressBar = "█" * $filled + "▒" * $empty
        
        Write-Host " [System]     $pct% [$progressBar]" -ForegroundColor Magenta
        
        Start-Sleep -Milliseconds 150
    }
    Write-Host "`n [OK] INTERFAZ LISTA. TODOS LOS MÓDULOS CARGADOS Y SEGUROS.`n" -ForegroundColor Green
    Start-Sleep -Milliseconds 600
}

function Show-Banner {
    Clear-Host
    $banner = @"
    ███████╗ ██████╗ ███╗   ███╗██████╗ ██████╗ ██╗ ██████╗
    ██╔════╝██╔═══██╗████╗ ████║██╔══██╗██╔══██╗██║██╔═══██╗
    ███████╗██║   ██║██╔████╔██║██████╔╝██████╔╝██║██║   ██║
    ╚════██║██║   ██║██║╚██╔╝██║██╔══██╗██╔══██╗██║██║   ██║
    ███████║╚██████╔╝██║ ╚═╝ ██║██████╔╝██║  ██║██║╚██████╔╝
    ╚══════╝ ╚═════╝ ╚═╝     ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝ ╚═════╝
"@
    Write-Host $banner -ForegroundColor DarkBlue
    Write-Host "                [ ADVANCED FORENSIC SCANNER ]                `n" -ForegroundColor Cyan
}

function Show-Header {
    param([string]$Subtitle)
    Clear-Host
    Write-Host "`n     ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkBlue
    Write-Host "     ║               EL SOMBRIO IF - FORENSIC SCANNER               ║" -ForegroundColor Cyan
    Write-Host "     ╠══════════════════════════════════════════════════════════════╣" -ForegroundColor DarkBlue
    $pad = [math]::Max(0, [math]::Floor((60 - $Subtitle.Length) / 2))
    $str = ((' ' * $pad) + $Subtitle).PadRight(60, ' ')
    Write-Host ("     ║{0}║" -f $str) -ForegroundColor White
    Write-Host "     ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkBlue
    Write-Host ""
}

function Pause-Scanner {
    Write-Host "`n"
    Invoke-Typewriter "     [ Presiona ENTER para regresar al menú principal ]" -Speed 10 -Color DarkGray
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
# [OPCION 1] MEOW MOD ANALYZER (NATIVO EN MEMORIA)
# ============================================================
function Start-FullModScan {
    Show-Header "ANÁLISIS AVANZADO DE MODS (MEOW MOD ANALYZER)"
    if (-not (Test-Administrator)) { Write-Host "     [!] Se requiere Administrador para ejecutar el Payload."; Pause-Scanner; return }

    Invoke-Typewriter "     [*] Inicializando motor MeowModAnalyzer desde GitHub..." -Color Cyan
    
    try {
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
        $url = "https://raw.githubusercontent.com/MeowTonynoh/MeowModAnalyzer/main/MeowModAnalyzer.ps1"
        $scriptContent = Invoke-RestMethod -Uri $url -UseBasicParsing
        
        Write-Host "     [+] Analizador descargado. Inyectando en memoria..." -ForegroundColor Green
        Start-Sleep -Seconds 1
        
        $scriptBlock = [ScriptBlock]::Create($scriptContent)
        & $scriptBlock
        
        Write-Host "`n     [✔] Análisis de mods finalizado correctamente." -ForegroundColor Green
    } catch { 
        Write-Host "`n     [!] Error al inyectar el analizador de mods: $($_.Exception.Message)" -ForegroundColor Red 
    }

    Pause-Scanner
}

# ============================================================
# [OPCION 2] ZEDOON DOOMSDAY DETECTOR (SCRIPT GITHUB)
# ============================================================
function Start-DoomsdayMemoryScan {
    Show-Header "DETECCIÓN PROFUNDA (DOOMSDAY DETECTOR)"
    if (-not (Test-Administrator)) { Write-Host "     [!] Se requiere Administrador."; Pause-Scanner; return }

    Invoke-Typewriter "     [*] Inicializando motor de detección remoto de Zedoon..." -Color Cyan
    
    try {
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
        $url = "https://raw.githubusercontent.com/zedoonvm1/powershell-scripts/refs/heads/main/DoomsDayDetector.ps1"
        $scriptContent = Invoke-RestMethod -Uri $url -UseBasicParsing
        
        Write-Host "     [+] Script cargado en memoria. Ejecutando..." -ForegroundColor Green
        Start-Sleep -Seconds 1
        
        $scriptBlock = [ScriptBlock]::Create($scriptContent)
        & $scriptBlock
        
        Write-Host "`n     [✔] Escaneo finalizado correctamente." -ForegroundColor Green
    } catch { 
        Write-Host "`n     [!] Error al inyectar el script: $($_.Exception.Message)" -ForegroundColor Red 
    }

    Pause-Scanner
}

# ============================================================
# [OPCION 3] PREFETCH + REGISTRO BAM (CON FECHAS)
# ============================================================
function Start-SystemScan {
    $todayStr = (Get-Date).ToString("yyyy-MM-dd")
    Show-Header "INTERVENCIÓN RÁPIDA (PREFETCH Y BAM)"
    if (-not (Test-Administrator)) { Write-Host "     [!] Se requieren privilegios de Administrador para leer BAM."; Pause-Scanner; return }

    $hallazgosAlertas = [System.Collections.Generic.List[string]]::new()
    Invoke-Typewriter "     [*] Extrayendo Registro BAM (Ejecuciones Ocultas)..." -Color Magenta
    $bamPath = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings\*"
    $bamEntries = Get-ItemProperty $bamPath -ErrorAction SilentlyContinue
    
    foreach ($entry in $bamEntries) {
        $props = $entry.psobject.properties | Where-Object { $_.Name -match "^[a-zA-Z]:\\" }
        foreach ($p in $props) {
            $filePath = $p.Name
            if ($filePath.ToLower() -match "click|autoclick|macro|jclicker|ghostclicker|meteor|totem|autototem") {
                Write-Host "     [BAM] [HACK / CLICKER] $filePath" -ForegroundColor Red
                
                $dateInfo = "Desconocida (Archivo borrado o no accesible)"
                if (Test-Path -LiteralPath $filePath -ErrorAction SilentlyContinue) {
                    $fileItem = Get-Item -LiteralPath $filePath -ErrorAction SilentlyContinue
                    $dateInfo = "Mod: $($fileItem.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) | Acc: $($fileItem.LastAccessTime.ToString('yyyy-MM-dd HH:mm'))"
                }
                Write-Host "           -> Fechas: $dateInfo" -ForegroundColor DarkGray

                $hallazgosAlertas.Add("BAM Oculto: $(Split-Path $filePath -Leaf)")
            }
        }
    }

    Write-Host "`n     [*] Actividad en Prefetch de Hoy ($todayStr):`n" -ForegroundColor Cyan
    $prefetchPath = "C:\Windows\Prefetch"
    if (Test-Path $prefetchPath) {
        $pfFiles = @(Get-ChildItem -Path $prefetchPath -Filter "*.pf" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
        $encontradosHoy = 0
        foreach ($pf in $pfFiles) {
            if ($pf.LastWriteTime.ToString("yyyy-MM-dd") -eq $todayStr) {
                $encontradosHoy++; $pName = $pf.Name.ToLower()
                if ($pName -match "click|autoclick|macro|jclicker|ghostclicker|meteor|totem|autototem") {
                    Write-Host "     [!] [HACK / CLICKER] $($pf.Name) | Ejecutado: $($pf.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Red
                    $hallazgosAlertas.Add("$($pf.Name) (Prefetch)")
                } elseif ($pName -like "*java*") { 
                    Write-Host "     [+] [JAVA EJECUTADO] $($pf.Name) | Ejecutado: $($pf.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Green 
                } else { 
                    Write-Host "     [i] [PROCESO] $($pf.Name) | Ejecutado: $($pf.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray 
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
    Invoke-Typewriter "     [*] Reconstruyendo índice de archivos eliminados...`n" -Color Cyan
    $hallazgosPapelera = [System.Collections.Generic.List[string]]::new()
    try {
        $shell = New-Object -ComObject Shell.Application
        $recycleBin = $shell.NameSpace(10)
        foreach ($item in $recycleBin.Items()) {
            $fechaElim = $recycleBin.GetDetailsOf($item, 2)
            Write-Host "     [!] $($item.Name) | Fecha Eliminado: $fechaElim" -ForegroundColor Red
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
    Invoke-Typewriter "     [*] Buscando perfiles de inyección de periféricos...`n" -Color Cyan
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
            Write-Host "     [!] Proceso de grabación interceptado: $($proc.Name) [PID: $($proc.Id)]" -ForegroundColor Yellow
            try { Write-Host "         Iniciado el: $($proc.StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor DarkGray } catch {}
        }
    }
    if ($detected.Count -eq 0) { Write-Host "`n     [+] Interferencia limpia. No hay procesos prohibidos activos." -ForegroundColor Green; Pause-Scanner; return }
    $choice = Read-Host "`n     ¿Ejecutar orden de cierre forzado? (S/N)"
    if ($choice.ToUpper() -eq "S") {
        foreach ($name in $detected) {
            Get-Process -Name $name -ErrorAction SilentlyContinue | Stop-Process -Force
            Write-Host "     [KILLED] $name.exe" -ForegroundColor Red
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
    Invoke-Typewriter "     [*] Escaneando DLLs alteradas en el último mes (30 días)..." -Color Cyan
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
                    Write-Host "     [!] DLL Anómala: $($file.Name) | Modificada: $($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Red
                    $hallazgosDLL.Add("$($file.Name) (Sin Firma)")
                }
            } catch {}
        }
    }
    Show-DetectionBox -Detections $hallazgosDLL -Title "DLLs ANÓMALAS O SIN FIRMA (ÚLTIMO MES)"
    Pause-Scanner
}

# ============================================================
# [OPCION 9] HUB DE HERRAMIENTAS SS
# ============================================================
function Start-SSToolsHub {
    Show-Header "HUB DE HERRAMIENTAS SS (EJECUCIÓN Y DESCARGAS)"
    Write-Host "     [*] Las Apps (.exe) se descargarán y ejecutarán al instante.`n" -ForegroundColor Cyan

    $tools = @(
        [PSCustomObject]@{ Id=1; Name="System Informer"; Url="https://sourceforge.net/projects/systeminformer/files/latest/download"; Icon="✦" }
        [PSCustomObject]@{ Id=2; Name="JournalTrace"; Url="https://github.com/ponei/JournalTrace/releases/download/1.0/JournalTrace.exe"; Icon="▶" }
    )

    foreach ($t in $tools) {
        $idPad = $t.Id.ToString().PadLeft(2, ' ')
        Write-Host "     [$idPad] $($t.Icon) $($t.Name)" -ForegroundColor White
    }

    while ($true) {
        $choice = (Read-Host "`n     [COMANDO] Ingresa ID para EJECUTAR/ABRIR (o 0 para salir)").Trim()
        if ($choice -eq "0") { break }
        
        $selected = $tools | Where-Object { $_.Id.ToString() -eq $choice }
        if ($selected) {
            if ($selected.Url -match "\.exe$" -or $selected.Url -match "download$") {
                Write-Host "     [*] Intentando descarga directa de $($selected.Name)..." -ForegroundColor Cyan
                $exeName = ($selected.Name -replace '\s','_') + ".exe"
                $exePath = "$env:TEMP\$exeName"
                try {
                    Write-Progress -Activity "Interceptando Payload" -Status $selected.Name
                    Invoke-WebRequest -Uri $selected.Url -OutFile $exePath -UseBasicParsing -TimeoutSec 15
                    Write-Progress -Activity "Interceptando Payload" -Completed
                    Write-Host "     [+] Ejecutando $($selected.Name)..." -ForegroundColor Green
                    Start-Process $exePath -Wait
                } catch { 
                    Write-Host "     [!] Descarga protegida por el servidor. Redirigiendo al navegador..." -ForegroundColor Yellow 
                    Start-Process $selected.Url
                }
            } else {
                Write-Host "     [+] Abriendo ruta externa para $($selected.Name)..." -ForegroundColor Green
                Start-Process $selected.Url
            }
        } else { Write-Host "     [!] Identificador no reconocido." -ForegroundColor Red }
    }
}

# ============================================================
# [OPCION 10] HUB DE PAYLOADS GITHUB (INYECCIÓN DIRECTA)
# ============================================================
function Start-RemoteScript {
    Show-Header "INYECCIÓN NATIVA DE SCRIPTS (PAYLOAD HUB)"
    if (-not (Test-Administrator)) { Write-Host "     [!] Acceso Denegado. Se requiere Ejecución como Administrador."; Pause-Scanner; return }

    Invoke-Typewriter "     [*] Selecciona el payload para inyectarlo directamente en memoria:`n" -Color Cyan

    $payloads = @(
        [PSCustomObject]@{ Id=1; Name="Lilith Services"; Url="https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Services.ps1" }
        [PSCustomObject]@{ Id=2; Name="Lilith Service-Enabler"; Url="https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Service-Enabler.ps1" }
        [PSCustomObject]@{ Id=3; Name="Ordiff Kill ScreenRecording"; Url="https://raw.githubusercontent.com/Orbdiff/powershell/refs/heads/main/kill-screen-processes.ps1" }
        [PSCustomObject]@{ Id=4; Name="Lilith DoomsdayFinder"; Url="https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/DoomsdayFinder.ps1" }
        [PSCustomObject]@{ Id=5; Name="RedLotus BamParser"; Url="https://raw.githubusercontent.com/PureIntent/ScreenShare/main/RedLotusBam.ps1" }
        [PSCustomObject]@{ Id=6; Name="Spouken BamParser"; Url="https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/bamparser.ps1" }
        [PSCustomObject]@{ Id=7; Name="RedLotus Prefetch Integrity"; Url="https://raw.githubusercontent.com/bacanoicua/Screenshare/main/RedLotusPrefetchIntegrityAnalyzer.ps1" }
        [PSCustomObject]@{ Id=8; Name="Florinyoq Bam Deleted Keys"; Url="https://raw.githubusercontent.com/Florinyoq/Screenshare/refs/heads/main/bam.ps1" }
    )

    foreach ($p in $payloads) {
        $idPad = $p.Id.ToString().PadLeft(2, ' ')
        Write-Host "     [$idPad] $($p.Name)" -ForegroundColor White
    }

    $choice = (Read-Host "`n     [COMANDO] ID de Inyección (o 0 para salir)").Trim()
    if ($choice -eq "0") { return }
    
    $selected = $payloads | Where-Object { $_.Id.ToString() -eq $choice }
    if ($selected) {
        Write-Host "`n     [*] Extrayendo código crudo de '$($selected.Name)'..." -ForegroundColor Yellow
        try {
            Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
            $scriptContent = Invoke-RestMethod -Uri $selected.Url -UseBasicParsing
            Write-Host "     [+] Código cargado. Iniciando Bypass de Memoria (ScriptBlock)..." -ForegroundColor Green
            Start-Sleep -Seconds 1
            $scriptBlock = [ScriptBlock]::Create($scriptContent)
            & $scriptBlock
            Write-Host "`n     [✔] Proceso finalizado." -ForegroundColor Green
        } catch { 
            Write-Host "`n     [!] Falla en la inyección de script: $($_.Exception.Message)" -ForegroundColor Red 
        }
    } else { Write-Host "     [!] Payload no encontrado." -ForegroundColor Red }

    Pause-Scanner
}

# ============================================================
# [OPCION 11] ANÁLISIS COMPLETO DEL DISCO
# ============================================================
function Start-FullDiskScan {
    Show-Header "ANÁLISIS COMPLETO DEL DISCO"
    Invoke-Typewriter "     [*] Escaneando C:\Users en busca de clientes ocultos..." -Color Cyan
    Write-Host "     [i] Operación intensiva. Esto tomará varios minutos.`n" -ForegroundColor DarkGray
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
                Write-Host "         Última Modificación: $($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
                $hallazgosDisco.Add("$($f.Name) | Carpeta: $($f.Directory.Name)")
            }
        }
    }
    Show-DetectionBox -Detections $hallazgosDisco -Title "ARCHIVOS SOSPECHOSOS EN EL DISCO"
    Pause-Scanner
}

# ============================================================
# [OPCION 12] RUTAS DE ANÁLISIS MANUAL (WIN + R)
# ============================================================
function Start-WinRCommands {
    Show-Header "RUTAS DE ANÁLISIS MANUAL (WINDOWS + R)"
    Write-Host "     [*] Atajos de sistema para análisis visual...`n" -ForegroundColor Cyan
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
    while ($true) {
        $choice = (Read-Host "`n     [COMANDO] ID para ABRIR (o 0 para salir)").Trim()
        if ($choice -eq "0") { break }
        $selected = $rutas | Where-Object { $_.Id.ToString() -eq $choice }
        if ($selected) {
            Write-Host "     [+] Ejecutando puente hacia $($selected.Cmd)..." -ForegroundColor Green
            try {
                if ($selected.Cmd -eq "regedit" -or $selected.Cmd -eq "msinfo32") { Start-Process $selected.Cmd } 
                else { Start-Process "explorer.exe" $selected.Cmd }
            } catch { Write-Host "     [!] Error de acceso." -ForegroundColor Red }
        } else { Write-Host "     [!] Comando no válido." -ForegroundColor Red }
    }
}

# ============================================================
# MENÚ PRINCIPAL
# ============================================================
function Show-MainMenu {
    if ($script:FirstRun) { Show-BootAnimation; $script:FirstRun = $false }
    while ($true) {
        try {
            Show-Banner
            $cat = @"
                                  /\_/\ 
                                 ( o.o )
                                  > ^ < 
"@
            Write-Host $cat -ForegroundColor Magenta
            Write-Host "     ╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor DarkGray
            Write-Host "     ║               [ MODULO CENTRAL DE INTERVENCION Y ESCANEO ]               ║" -ForegroundColor Magenta
            Write-Host "     ╠══════════════════════════════════════════════════════════════════════════╣" -ForegroundColor DarkGray
            Write-Host "     ║ [ 1 ] Analizar Mods (MeowAnalyzer) ║ [ 7 ] Servicios Windows             ║" -ForegroundColor Cyan
            Write-Host "     ║ [ 2 ] Doomsday Detector (Zedoon)   ║ [ 8 ] Análisis DLLs (1 MES)         ║" -ForegroundColor Cyan
            Write-Host "     ║ [ 3 ] Análisis Prefetch/BAM        ║ [ 9 ] Hub Herramientas SS           ║" -ForegroundColor Cyan
            Write-Host "     ║ [ 4 ] Análisis Papelera            ║ [10 ] Hub Payloads (GitHub)         ║" -ForegroundColor Cyan
            Write-Host "     ║ [ 5 ] Auditoría de Macros          ║ [11 ] Análisis Completo Disco       ║" -ForegroundColor Cyan
            Write-Host "     ║ [ 6 ] Killer Screen (Diff)         ║ [12 ] Rutas Manuales (Win+R)        ║" -ForegroundColor Cyan
            Write-Host "     ║                                    ║ [13 ] Salir de Framework            ║" -ForegroundColor Red
            Write-Host "     ╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGray
            
            $option = (Read-Host "`n     [ROOT] Selecciona un módulo [1-13]").Trim()
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
                "11"{ Start-FullDiskScan }
                "12"{ Start-WinRCommands }
                "13"{ Clear-Host; Invoke-Typewriter "`n     [!] CERRANDO CONEXIÓN. HASTA LUEGO, JOAQUÍN.`n" -Color Red; return }
                default { Write-Host "`n     [!] Entrada no reconocida en el sistema." -ForegroundColor Red; Start-Sleep -Seconds 1 }
            }
        } catch {
            Write-Host "`n     [!] Interrupción detectada. Forzando reinicio de interfaz." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}

Show-MainMenu
