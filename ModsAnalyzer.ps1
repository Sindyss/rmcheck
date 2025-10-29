param(
    [string]$InputDir,
    [string]$OutputRoot = "C:\modscan",
    [string]$ToolsRoot = "$env:USERPROFILE\decompiler-tools",
    [string]$CfrFileName = "cfr.jar",
    [int]$ContextLines = 5,
    [int]$HighConfidenceThreshold = 2,
    [switch]$Overwrite
)

# Если путь не указан, запрашиваем у пользователя
if ([string]::IsNullOrEmpty($InputDir)) {
    Write-Host "📁 Введите путь к папке с модами для анализа:" -ForegroundColor Yellow
    $InputDir = Read-Host "Путь"
    
    # Проверяем, что путь существует
    while (-not (Test-Path $InputDir)) {
        Write-Host "❌ Указанная папка не существует!" -ForegroundColor Red
        Write-Host "📁 Введите корректный путь к папке с модами:" -ForegroundColor Yellow
        $InputDir = Read-Host "Путь"
    }
}

$CfrUrl = "https://github.com/leibnitz27/cfr/releases/download/0.152/cfr-0.152.jar"
$CfrLocalPath = Join-Path $ToolsRoot $CfrFileName

$CheatMappings = @{
    "Hitbox" = @{
        Critical = @(
            @{Type = "method"; Pattern = "m_20011_"},
            @{Type = "method"; Pattern = "func_174813_aQ"},
            @{Type = "method"; Pattern = "setBoundingBox"},
            @{Type = "method"; Pattern = "getEntityBoundingBox"},
            @{Type = "method"; Pattern = "setEntityBoundingBox"},
            @{Type = "method"; Pattern = "getBoundingBox"},
            @{Type = "method"; Pattern = "boundingBox.*expand"},
            @{Type = "method"; Pattern = "boundingBox.*grow"},
            @{Type = "method"; Pattern = "boundingBox.*scale"},
            @{Type = "method"; Pattern = "boundingBox.*multiply"},
            @{Type = "method"; Pattern = "expand.*boundingBox"},
            @{Type = "method"; Pattern = "grow.*boundingBox"},
            @{Type = "method"; Pattern = "scale.*boundingBox"},
            @{Type = "method"; Pattern = "minX\s*[\-\+]\s*[\d\.]"},
            @{Type = "method"; Pattern = "maxX\s*[\-\+]\s*[\d\.]"},
            @{Type = "method"; Pattern = "minY\s*[\-\+]\s*[\d\.]"},
            @{Type = "method"; Pattern = "maxY\s*[\-\+]\s*[\d\.]"},
            @{Type = "method"; Pattern = "minZ\s*[\-\+]\s*[\d\.]"},
            @{Type = "method"; Pattern = "maxZ\s*[\-\+]\s*[\d\.]"},
            @{Type = "method"; Pattern = "minX\s*=\s*.*[\-\+].*[\d\.]"},
            @{Type = "method"; Pattern = "maxX\s*=\s*.*[\-\+].*[\d\.]"},
            @{Type = "method"; Pattern = "minY\s*=\s*.*[\-\+].*[\d\.]"},
            @{Type = "method"; Pattern = "maxY\s*=\s*.*[\-\+].*[\d\.]"},
            @{Type = "method"; Pattern = "minZ\s*=\s*.*[\-\+].*[\d\.]"},
            @{Type = "method"; Pattern = "maxZ\s*=\s*.*[\-\+].*[\d\.]"},
            @{Type = "method"; Pattern = "cD\(\)\s*[\-\+]\s*[\d\.]"},
            @{Type = "method"; Pattern = "cH\(\)\s*[\-\+]\s*[\d\.]"},
            @{Type = "method"; Pattern = "cc\(\).b"},
            @{Type = "method"; Pattern = "cc\(\).e"},
            @{Type = "method"; Pattern = "new dci\(.*[\-\+].*[\d\.]"},
            @{Type = "method"; Pattern = "new AABB\(.*[\-\+].*[\d\.]"},
            @{Type = "method"; Pattern = "dci\(.*[\-\+].*[\d\.]"},
            @{Type = "method"; Pattern = "AABB\(.*[\-\+].*[\d\.]"},
            @{Type = "field"; Pattern = "field_72338_b"},
            @{Type = "field"; Pattern = "field_72337_e"},
            @{Type = "field"; Pattern = "field_72333_a"},
            @{Type = "field"; Pattern = "field_72336_d"},
            @{Type = "method"; Pattern = "expandHitbox"},
            @{Type = "method"; Pattern = "growHitbox"},
            @{Type = "method"; Pattern = "resizeHitbox"},
            @{Type = "method"; Pattern = "modifyHitbox"},
            @{Type = "method"; Pattern = "changeHitbox"},
            @{Type = "method"; Pattern = "setHitbox"},
            @{Type = "method"; Pattern = "getHitbox"},
            @{Type = "method"; Pattern = "updateHitbox"},
            @{Type = "method"; Pattern = "adjustHitbox"},
            @{Type = "method"; Pattern = "collisionBox"},
            @{Type = "method"; Pattern = "getCollisionBox"},
            @{Type = "method"; Pattern = "setCollisionBox"},
            @{Type = "method"; Pattern = "collisionBoundingBox"},
            @{Type = "method"; Pattern = "size.*hitbox"},
            @{Type = "method"; Pattern = "hitbox.*size"},
            @{Type = "method"; Pattern = "setSize.*hitbox"},
            @{Type = "method"; Pattern = "hitbox.*width"},
            @{Type = "method"; Pattern = "hitbox.*height"},
            @{Type = "method"; Pattern = "hitbox.*scale"},
            @{Type = "method"; Pattern = "player.*boundingBox"},
            @{Type = "method"; Pattern = "entity.*boundingBox"},
            @{Type = "method"; Pattern = "player.*a\(.*dci"},
            @{Type = "method"; Pattern = "entity.*a\(.*dci"},
            @{Type = "method"; Pattern = "attack.*boundingBox"},
            @{Type = "method"; Pattern = "hitbox.*reach"},
            @{Type = "method"; Pattern = "reach.*hitbox"},
            @{Type = "method"; Pattern = "flag.*[\d\.]"},
            @{Type = "method"; Pattern = "hitbox.*flag"},
            @{Type = "method"; Pattern = "config.*hitbox"},
            @{Type = "method"; Pattern = "hitbox.*config"},
            @{Type = "method"; Pattern = "setting.*hitbox"},
            @{Type = "method"; Pattern = "hitbox.*setting"},
            @{Type = "method"; Pattern = "minX\s*[\-\+]\s*\w+\s*[\-\+]\s*[\d\.]"},
            @{Type = "method"; Pattern = "maxX\s*[\-\+]\s*\w+\s*[\-\+]\s*[\d\.]"},
            @{Type = "method"; Pattern = "Math\.max.*minX"},
            @{Type = "method"; Pattern = "Math\.min.*maxX"},
            @{Type = "method"; Pattern = "minX\s*=\s*Math\."},
            @{Type = "method"; Pattern = "maxX\s*=\s*Math\."}
        )
        Suspicious = @(
            @{Type = "method"; Pattern = "dci"},
            @{Type = "method"; Pattern = "AABB"},
            @{Type = "method"; Pattern = "cD\(\)"},
            @{Type = "method"; Pattern = "cH\(\)"},
            @{Type = "method"; Pattern = "cc\(\)"},
            @{Type = "method"; Pattern = "a\("},
            @{Type = "method"; Pattern = "boundingBox"},
            @{Type = "method"; Pattern = "hitbox"},
            @{Type = "method"; Pattern = "collision"},
            @{Type = "method"; Pattern = "expand"},
            @{Type = "method"; Pattern = "grow"},
            @{Type = "method"; Pattern = "resize"},
            @{Type = "method"; Pattern = "size"},
            @{Type = "method"; Pattern = "flag"},
            @{Type = "method"; Pattern = "scale"},
            @{Type = "method"; Pattern = "multiply"},
            @{Type = "method"; Pattern = "adjust"},
            @{Type = "method"; Pattern = "modify"},
            @{Type = "method"; Pattern = "minX"},
            @{Type = "method"; Pattern = "maxX"},
            @{Type = "method"; Pattern = "minY"},
            @{Type = "method"; Pattern = "maxY"},
            @{Type = "method"; Pattern = "minZ"},
            @{Type = "method"; Pattern = "maxZ"}
        )
    }
    "TriggerBot" = @{
        Critical = @(
            @{Type = "method"; Pattern = "clickMouse"},
            @{Type = "method"; Pattern = "attackEntity"},
            @{Type = "method"; Pattern = "func_78764_a"},
            @{Type = "method"; Pattern = "autoAttack"},
            @{Type = "method"; Pattern = "triggerBot"},
            @{Type = "method"; Pattern = "trigger"},
            @{Type = "method"; Pattern = "autoClick"},
            @{Type = "method"; Pattern = "doAttack"},
            @{Type = "method"; Pattern = "onAttack"},
            @{Type = "method"; Pattern = "checkTarget"},
            @{Type = "method"; Pattern = "shouldAttack"},
            @{Type = "method"; Pattern = "attackIfValid"},
            @{Type = "method"; Pattern = "triggerKey"},
            @{Type = "method"; Pattern = "autoTrigger"}
        )
        Suspicious = @(
            @{Type = "method"; Pattern = "attack.*delay"},
            @{Type = "method"; Pattern = "target.*entity"},
            @{Type = "method"; Pattern = "entity.*target"},
            @{Type = "method"; Pattern = "rayTrace"},
            @{Type = "method"; Pattern = "lookingAt"},
            @{Type = "method"; Pattern = "crosshair"},
            @{Type = "method"; Pattern = "auto.*attack"},
            @{Type = "method"; Pattern = "mouse.*click"},
            @{Type = "method"; Pattern = "leftClick"}
        )
    }
    "Reach" = @{
        Critical = @(
            @{Type = "method"; Pattern = "getReachDistance"},
            @{Type = "method"; Pattern = "func_110148_a"},
            @{Type = "method"; Pattern = "extendReach"},
            @{Type = "method"; Pattern = "attackRange"},
            @{Type = "method"; Pattern = "blockReachDistance"},
            @{Type = "method"; Pattern = "entityReach"},
            @{Type = "method"; Pattern = "reach.*distance"},
            @{Type = "method"; Pattern = "distance.*modif"},
            @{Type = "method"; Pattern = "setReach"},
            @{Type = "method"; Pattern = "modifyReach"},
            @{Type = "method"; Pattern = "getAttackRange"},
            @{Type = "method"; Pattern = "range.*extend"},
            @{Type = "method"; Pattern = "combatRange"},
            @{Type = "method"; Pattern = "hitRange"}
        )
        Suspicious = @(
            @{Type = "method"; Pattern = "blockReach"},
            @{Type = "method"; Pattern = "distance.*modif"},
            @{Type = "method"; Pattern = "range.*increase"},
            @{Type = "method"; Pattern = "attack.*range"},
            @{Type = "method"; Pattern = "player.*reach"},
            @{Type = "method"; Pattern = "entity.*distance"},
            @{Type = "method"; Pattern = "target.*range"}
        )
    }
    "GlowESP" = @{
        Critical = @(
            @{Type = "method"; Pattern = "m_146915_"},
            @{Type = "method"; Pattern = "setGlowing"},
            @{Type = "method"; Pattern = "func_184195_f"},
            @{Type = "method"; Pattern = "glowing.*true"},
            @{Type = "method"; Pattern = "setOutline"},
            @{Type = "method"; Pattern = "enableGlow"},
            @{Type = "method"; Pattern = "addGlow"},
            @{Type = "method"; Pattern = "makeGlow"},
            @{Type = "method"; Pattern = "glowEffect"},
            @{Type = "method"; Pattern = "entityGlow"},
            @{Type = "method"; Pattern = "outlineEntity"}
        )
        Suspicious = @(
            @{Type = "method"; Pattern = "outline"},
            @{Type = "method"; Pattern = "entityOutline"},
            @{Type = "method"; Pattern = "renderOutline"},
            @{Type = "method"; Pattern = "glow"},
            @{Type = "method"; Pattern = "highlight"},
            @{Type = "method"; Pattern = "esp"},
            @{Type = "method"; Pattern = "chams"},
            @{Type = "method"; Pattern = "wallhack"}
        )
    }
    "AutoTotem" = @{
        Critical = @(
            @{Type = "method"; Pattern = "getOffhandItem"},
            @{Type = "method"; Pattern = "func_187098_a"},
            @{Type = "method"; Pattern = "autoTotem"},
            @{Type = "method"; Pattern = "refillTotem"},
            @{Type = "method"; Pattern = "totemRefill"},
            @{Type = "method"; Pattern = "checkTotem"},
            @{Type = "method"; Pattern = "replaceTotem"},
            @{Type = "method"; Pattern = "autoTotemDelay"},
            @{Type = "method"; Pattern = "offhandManager"},
            @{Type = "method"; Pattern = "totemManager"}
        )
        Suspicious = @(
            @{Type = "method"; Pattern = "offhand.*totem"},
            @{Type = "method"; Pattern = "survivalInventory"},
            @{Type = "method"; Pattern = "offhand.*slot"},
            @{Type = "method"; Pattern = "totem.*check"},
            @{Type = "method"; Pattern = "health.*totem"},
            @{Type = "method"; Pattern = "death.*totem"},
            @{Type = "method"; Pattern = "lowHealth.*totem"}
        )
    }
    "ClickPearl" = @{
        Critical = @(
            @{Type = "method"; Pattern = "rightClickDelay"},
            @{Type = "method"; Pattern = "func_71011_aU"},
            @{Type = "method"; Pattern = "fastUse"},
            @{Type = "method"; Pattern = "fastPlace"},
            @{Type = "method"; Pattern = "pearlDelay"},
            @{Type = "method"; Pattern = "useItemDelay"},
            @{Type = "method"; Pattern = "reduceDelay"},
            @{Type = "method"; Pattern = "clickDelay"},
            @{Type = "method"; Pattern = "fastPearl"},
            @{Type = "method"; Pattern = "instantUse"}
        )
        Suspicious = @(
            @{Type = "method"; Pattern = "useItemDelay"},
            @{Type = "method"; Pattern = "pearlDelay"},
            @{Type = "method"; Pattern = "enderPearl"},
            @{Type = "method"; Pattern = "rightClick"},
            @{Type = "method"; Pattern = "useItem"},
            @{Type = "method"; Pattern = "itemUseCooldown"},
            @{Type = "method"; Pattern = "cooldown.*reduce"}
        )
    }
    "Fly" = @{
        Critical = @(
            @{Type = "method"; Pattern = "onUpdate"},
            @{Type = "method"; Pattern = "moveEntity"},
            @{Type = "method"; Pattern = "setMotion"},
            @{Type = "method"; Pattern = "noClip"},
            @{Type = "method"; Pattern = "setNoGravity"},
            @{Type = "method"; Pattern = "fly"},
            @{Type = "method"; Pattern = "flight"},
            @{Type = "method"; Pattern = "hover"},
            @{Type = "method"; Pattern = "antiFall"},
            @{Type = "method"; Pattern = "creativeFly"},
            @{Type = "method"; Pattern = "jetpack"},
            @{Type = "method"; Pattern = "airJump"}
        )
        Suspicious = @(
            @{Type = "method"; Pattern = "motionY"},
            @{Type = "method"; Pattern = "fallDistance"},
            @{Type = "method"; Pattern = "onGround"},
            @{Type = "method"; Pattern = "jump"},
            @{Type = "method"; Pattern = "velocity"},
            @{Type = "method"; Pattern = "flying"},
            @{Type = "method"; Pattern = "airborne"}
        )
    }
    "Speed" = @{
        Critical = @(
            @{Type = "method"; Pattern = "setSpeed"},
            @{Type = "method"; Pattern = "moveSpeed"},
            @{Type = "method"; Pattern = "speedModifier"},
            @{Type = "method"; Pattern = "motionX.*=.*motionX.*\*"},
            @{Type = "method"; Pattern = "motionZ.*=.*motionZ.*\*"},
            @{Type = "method"; Pattern = "horizontalCollision"},
            @{Type = "method"; Pattern = "strafe"},
            @{Type = "method"; Pattern = "speedHack"},
            @{Type = "method"; Pattern = "bunnyHop"},
            @{Type = "method"; Pattern = "timerSpeed"}
        )
        Suspicious = @(
            @{Type = "method"; Pattern = "motionX"},
            @{Type = "method"; Pattern = "motionZ"},
            @{Type = "method"; Pattern = "movement.*speed"},
            @{Type = "method"; Pattern = "moveForward"},
            @{Type = "method"; Pattern = "moveStrafing"},
            @{Type = "method"; Pattern = "sprint"},
            @{Type = "method"; Pattern = "velocity"},
            @{Type = "method"; Pattern = "acceleration"}
        )
    }
    "KillAura" = @{
        Critical = @(
            @{Type = "method"; Pattern = "killAura"},
            @{Type = "method"; Pattern = "attackAll"},
            @{Type = "method"; Pattern = "multiAttack"},
            @{Type = "method"; Pattern = "entityList.*attack"},
            @{Type = "method"; Pattern = "for.*Entity.*attack"},
            @{Type = "method"; Pattern = "radiusAttack"},
            @{Type = "method"; Pattern = "areaAttack"}
        )
        Suspicious = @(
            @{Type = "method"; Pattern = "entityList"},
            @{Type = "method"; Pattern = "world.*entities"},
            @{Type = "method"; Pattern = "getEntities"},
            @{Type = "method"; Pattern = "for.*entity"},
            @{Type = "method"; Pattern = "multiple.*target"},
            @{Type = "method"; Pattern = "radius.*check"}
        )
    }
}

$ObfuscationPatterns = @{
    "ProGuard" = @(
        '[a-z]{1,2}\.[a-z]{1,2}\.[a-z]{1,2}',
        '\b[a-z]{1,2}\b',
        'class_[a-zA-Z]+',
        'field_[a-zA-Z]+',
        'method_[a-zA-Z]+'
    )
    "MCP" = @(
        'func_\d+',
        'field_\d+',
        'p_\d+'
    )
    "Allatori" = @(
        '[^\u0000-\u007F]',
        'ï', '¿', '½',
        'ￃﾁ', 'ￃﾂ', 'ￃﾃ'
    )
    "Zelix" = @(
        'Z\.', 'Y\.', 'X\.',
        '_\$\d+',
        '\$[A-Z]\$'
    )
    "Colonial" = @(
        '_[0-9a-zA-Z]{16,}',
        '[a-z]+[0-9]+[a-z]+[0-9]+',
        '[A-Z][a-z]+[0-9]+[A-Z]',
        'lllll|iiiii|ooooo',
        'I1I1I|O0O0O',
        'var_[0-9a-fA-F]+',
        'field_[0-9a-fA-F]+',
        'method_[0-9a-fA-F]+'
    )
}

function Ensure-Java {
    try {
        $ver = & java -version 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Java не обнаружена в PATH." }
        Write-Host "✓ Java найдена" -ForegroundColor Green
    } catch {
        Write-Error "❌ Требуется Java (JRE/JDK) в PATH."
        exit 2
    }
}

function Download-CFR {
    param($destPath, $url)
    if ((Test-Path $destPath) -and (-not $Overwrite)) { 
        Write-Host "✓ CFR уже скачан" -ForegroundColor Green
        return 
    }
    Write-Host "📥 Скачиваем CFR..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $url -OutFile $destPath -UseBasicParsing
        Write-Host "✓ CFR успешно скачан" -ForegroundColor Green
    } catch {
        Write-Error "❌ Ошибка скачивания CFR: $($_.Exception.Message)"
        exit 3
    }
}

function Decompile-Jar {
    param([string]$JarPath, [string]$OutRoot)

    $base = [IO.Path]::GetFileNameWithoutExtension($JarPath)
    $outDir = Join-Path $OutRoot $base
    
    if ((Test-Path $outDir) -and (-not $Overwrite)) { 
        Write-Host "  ⏭️  Пропускаем (уже существует): $base" -ForegroundColor Yellow
        return 
    }
    
    if (Test-Path $outDir) {
        Remove-Item -Path $outDir -Recurse -Force
    }
    
    New-Item -Path $outDir -ItemType Directory -Force | Out-Null

    Write-Host "  🔨 Декомпилируем: $base" -ForegroundColor Cyan

    $tempDir = Join-Path $outDir "_tmp"
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

    $process = Start-Process -FilePath "java" -ArgumentList @("-jar", $CfrLocalPath, $JarPath, "--outputdir", $tempDir, "--silent", "true") -NoNewWindow -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        $javaFiles = Get-ChildItem -Path $tempDir -Recurse -Filter *.java
        foreach ($file in $javaFiles) {
            $relativePath = $file.FullName.Replace($tempDir, "").TrimStart("\")
            $targetDir = Join-Path $outDir (Split-Path $relativePath -Parent)
            if (-not (Test-Path $targetDir)) {
                New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
            }
            Copy-Item $file.FullName -Destination (Join-Path $outDir $relativePath) -Force
        }
        Write-Host "  ✓ Успешно: $base ($($javaFiles.Count) файлов)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Ошибка декомпиляции: $base" -ForegroundColor Red
    }

    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

function Extract-Classes {
    Write-Host "`n" + "=" * 70 -ForegroundColor Cyan
    Write-Host "             ЭТАП 1: ИЗВЛЕЧЕНИЕ КЛАССОВ ИЗ JAR" -ForegroundColor Yellow
    Write-Host "=" * 70 -ForegroundColor Cyan
    
    Write-Host "Входная папка: $InputDir" -ForegroundColor Gray
    Write-Host "Выходная папка: $OutputRoot" -ForegroundColor Gray
    Write-Host ""

    New-Item -Path $ToolsRoot -ItemType Directory -Force | Out-Null
    New-Item -Path $OutputRoot -ItemType Directory -Force | Out-Null

    Ensure-Java

    Download-CFR -destPath $CfrLocalPath -url $CfrUrl

    # Ищем только в указанной папке, без рекурсии в системные директории
    $jarFiles = Get-ChildItem -Path $InputDir -Filter *.jar -File
    Write-Host "Найдено JAR файлов: $($jarFiles.Count)" -ForegroundColor Cyan

    if ($jarFiles.Count -eq 0) {
        Write-Error "❌ JAR файлы не найдены в указанной директории"
        Write-Host "Убедитесь, что в папке '$InputDir' есть .jar файлы модов" -ForegroundColor Yellow
        exit 1
    }

    $counter = 0
    foreach ($jar in $jarFiles) {
        $counter++
        Write-Host "[$counter/$($jarFiles.Count)] " -NoNewline -ForegroundColor Gray
        try {
            Decompile-Jar -JarPath $jar.FullName -OutRoot $OutputRoot
        } catch {
            Write-Host "  ❌ Ошибка: $($jar.Name) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "`n✅ Извлечение классов завершено!" -ForegroundColor Green
    return $OutputRoot
}

function Get-CodeContext {
    param([array]$Lines, [int]$LineNumber, [int]$ContextSize)
    
    $start = [Math]::Max(1, $LineNumber - $ContextSize)
    $end = [Math]::Min($Lines.Count, $LineNumber + $ContextSize)
    
    $context = @()
    for ($i = $start; $i -le $end; $i++) {
        $prefix = if ($i -eq $LineNumber) { ">>> " } else { "    " }
        $context += "$prefix$i`: $($Lines[$i-1])"
    }
    
    return $context -join "`n"
}

function Find-CheatPatterns {
    param([string]$FilePath, [string]$JarName)
    
    $results = @()
    
    try {
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        $lines = Get-Content -Path $FilePath
        $fileName = Split-Path $FilePath -Leaf
        
        foreach ($cheatCategory in $CheatMappings.Keys) {
            $config = $CheatMappings[$cheatCategory]
            
            foreach ($pattern in $config.Critical) {
                try {
                    $regexOptions = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
                    $matches = [regex]::Matches($content, $pattern.Pattern, $regexOptions)
                    
                    foreach ($match in $matches) {
                        $lineNumber = 0
                        $currentPos = 0
                        for ($i = 0; $i -lt $lines.Count; $i++) {
                            $currentPos += $lines[$i].Length + 1
                            if ($currentPos -ge $match.Index) {
                                $lineNumber = $i + 1
                                break
                            }
                        }
                        
                        if ($lineNumber -gt 0) {
                            $context = Get-CodeContext -Lines $lines -LineNumber $lineNumber -ContextSize $ContextLines
                            
                            $results += [PSCustomObject]@{
                                JarName = $JarName
                                FileName = $fileName
                                LineNumber = $lineNumber
                                CheatCategory = $cheatCategory
                                PatternType = $pattern.Type
                                Pattern = $pattern.Pattern
                                Confidence = "HIGH"
                                Context = $context
                                MatchText = $match.Value
                            }
                        }
                    }
                }
                catch {
                    Write-Warning "Ошибка в паттерне $($pattern.Pattern): $($_.Exception.Message)"
                }
            }
        }
    }
    catch {
        Write-Warning "Не удалось прочитать файл $FilePath"
    }
    
    return $results
}

function Test-Obfuscation {
    param([string]$Content)
    
    $obfuscationResults = @()
    
    foreach ($obfType in $ObfuscationPatterns.Keys) {
        $score = 0
        foreach ($pattern in $ObfuscationPatterns[$obfType]) {
            try {
                $matches = [regex]::Matches($Content, $pattern)
                $score += $matches.Count
            }
            catch {
            }
        }
        
        if ($score -gt 0) {
            $obfuscationResults += [PSCustomObject]@{
                Type = $obfType
                Score = $score
            }
        }
    }
    
    return $obfuscationResults | Sort-Object Score -Descending
}

function Get-JarAnalysisResult {
    param([string]$JarPath, [string]$JarName)
    
    $cheatResults = @()
    $obfuscationTypes = @{}
    
    $javaFiles = Get-ChildItem -Path $JarPath -Recurse -Filter "*.java"
    
    Write-Host "    📊 Анализ $($javaFiles.Count) файлов..." -ForegroundColor Gray
    
    foreach ($javaFile in $javaFiles) {
        $fileCheatResults = Find-CheatPatterns -FilePath $javaFile.FullName -JarName $JarName
        $cheatResults += $fileCheatResults
        
        try {
            $content = Get-Content -Path $javaFile.FullName -Raw -ErrorAction Stop
            $fileObfuscation = Test-Obfuscation -Content $content
            foreach ($obf in $fileObfuscation) {
                if (-not $obfuscationTypes.ContainsKey($obf.Type)) {
                    $obfuscationTypes[$obf.Type] = 0
                }
                $obfuscationTypes[$obf.Type] += $obf.Score
            }
        }
        catch {
        }
    }
    
    $highConfidenceCount = ($cheatResults | Where-Object { $_.Confidence -eq "HIGH" }).Count
    $threatLevel = if ($highConfidenceCount -ge $HighConfidenceThreshold) { 
        "HIGH" 
    } elseif ($highConfidenceCount -gt 0) { 
        "MEDIUM" 
    } elseif ($cheatResults.Count -gt 0) { 
        "LOW" 
    } else { 
        "CLEAN" 
    }
    
    return @{
        JarName = $JarName
        ThreatLevel = $threatLevel
        CheatResults = $cheatResults
        ObfuscationTypes = $obfuscationTypes
        TotalFiles = $javaFiles.Count
        TotalDetections = $cheatResults.Count
        HighConfidenceDetections = $highConfidenceCount
    }
}

function Analyze-Classes {
    param([string]$SourceDirectory)
    
    Write-Host "`n" + "=" * 70 -ForegroundColor Cyan
    Write-Host "             ЭТАП 2: АНАЛИЗ ЧИТЕРСКИХ МОДИФИКАЦИЙ" -ForegroundColor Yellow
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host "Анализируемая папка: $SourceDirectory" -ForegroundColor Gray
    Write-Host ""
    
    $jarFolders = Get-ChildItem -Path $SourceDirectory -Directory
    $analysisResults = @()
    $threatSummary = @{
        HIGH = 0
        MEDIUM = 0
        LOW = 0
        CLEAN = 0
        OBFUSCATED = 0
    }
    
    foreach ($jarFolder in $jarFolders) {
        Write-Host "🔍 Анализируем: " -NoNewline -ForegroundColor Cyan
        Write-Host $jarFolder.Name -ForegroundColor White
        
        $jarResult = Get-JarAnalysisResult -JarPath $jarFolder.FullName -JarName $jarFolder.Name
        $analysisResults += $jarResult
        
        $threatSummary[$jarResult.ThreatLevel]++
        if ($jarResult.ObfuscationTypes.Count -gt 0) {
            $threatSummary.OBFUSCATED++
        }
        
        $threatColor = switch ($jarResult.ThreatLevel) {
            "HIGH" { "Red" }
            "MEDIUM" { "Yellow" }
            "LOW" { "Magenta" }
            default { "Green" }
        }
        
        Write-Host "  Уровень угрозы: " -NoNewline -ForegroundColor Gray
        Write-Host $jarResult.ThreatLevel -ForegroundColor $threatColor
        
        if ($jarResult.TotalDetections -gt 0) {
            Write-Host "  Обнаружено совпадений: " -NoNewline -ForegroundColor Gray
            Write-Host "$($jarResult.TotalDetections) " -NoNewline -ForegroundColor White
            Write-Host "($($jarResult.HighConfidenceDetections) высокой уверенности)" -ForegroundColor Red
            
            $cheatCategories = $jarResult.CheatResults | Group-Object CheatCategory | Sort-Object Count -Descending
            Write-Host "  Категории читов:" -ForegroundColor Gray
            foreach ($category in $cheatCategories) {
                $highCount = ($category.Group | Where-Object { $_.Confidence -eq "HIGH" }).Count
                Write-Host "    - $($category.Name): $($category.Count) ($highCount высокой уверенности)" -ForegroundColor White
            }
            
            $highExamples = $jarResult.CheatResults | Where-Object { $_.Confidence -eq "HIGH" } | Select-Object -First 2
            if ($highExamples.Count -gt 0) {
                Write-Host "  Примеры обнаружений:" -ForegroundColor Gray
                foreach ($example in $highExamples) {
                    Write-Host "    Файл: $($example.FileName):$($example.LineNumber)" -ForegroundColor DarkYellow
                    Write-Host "    Паттерн: $($example.Pattern)" -ForegroundColor DarkCyan
                    Write-Host "    Контекст:" -ForegroundColor DarkGray
                    $example.Context -split "`n" | ForEach-Object { Write-Host "      $_" -ForegroundColor Gray }
                    Write-Host ""
                }
            }
        } else {
            Write-Host "  Обнаружено совпадений: 0" -ForegroundColor Green
        }
        
        if ($jarResult.ObfuscationTypes.Count -gt 0) {
            Write-Host "  Обфускация: " -NoNewline -ForegroundColor Gray
            $obfTypes = ($jarResult.ObfuscationTypes.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 3).Key -join ", "
            Write-Host $obfTypes -ForegroundColor Magenta
        }
        
        Write-Host ""
    }
    
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host "                     СВОДКА АНАЛИЗА" -ForegroundColor Yellow
    Write-Host "=" * 70 -ForegroundColor Cyan
    
    Write-Host "📊 Общая статистика:" -ForegroundColor White
    Write-Host "   Всего JAR файлов: $($jarFolders.Count)" -ForegroundColor Cyan
    Write-Host "   🚨 Высокая угроза: $($threatSummary.HIGH)" -ForegroundColor Red
    Write-Host "   ⚠  Средняя угроза: $($threatSummary.MEDIUM)" -ForegroundColor Yellow
    Write-Host "   🔍 Низкая угроза: $($threatSummary.LOW)" -ForegroundColor Magenta
    Write-Host "   ✅ Чистые: $($threatSummary.CLEAN)" -ForegroundColor Green
    Write-Host "   🎭 Обфусцированные: $($threatSummary.OBFUSCATED)" -ForegroundColor Magenta
    
    $allDetections = $analysisResults | ForEach-Object { $_.CheatResults } | Group-Object CheatCategory | Sort-Object Count -Descending
    
    if ($allDetections.Count -gt 0) {
        Write-Host "`n📈 Статистика по категориям читов:" -ForegroundColor White
        foreach ($detection in $allDetections) {
            $highCount = ($detection.Group | Where-Object { $_.Confidence -eq "HIGH" }).Count
            Write-Host "   - $($detection.Name): $($detection.Count) обнаружений ($highCount высокой уверенности)" -ForegroundColor Cyan
        }
    }
    
    if ($threatSummary.HIGH -gt 0) {
        Write-Host "`n🚨 ВНИМАНИЕ: Обнаружены файлы с высокой угрозой!" -ForegroundColor Red -BackgroundColor Black
        $highThreatJars = $analysisResults | Where-Object { $_.ThreatLevel -eq "HIGH" }
        Write-Host "   Подозрительные файлы:" -ForegroundColor Yellow
        foreach ($jar in $highThreatJars) {
            Write-Host "   - $($jar.JarName)" -ForegroundColor Red
        }
    } else {
        Write-Host "`n✅ Высокорисковые читы не обнаружены" -ForegroundColor Green
    }
    
    return $analysisResults
}

function Cleanup-ExtractedClasses {
    param([string]$ExtractedPath)
    
    Write-Host "`n" + "=" * 70 -ForegroundColor Cyan
    Write-Host "             ЭТАП 3: ОЧИСТКА ВРЕМЕННЫХ ФАЙЛОВ" -ForegroundColor Yellow
    Write-Host "=" * 70 -ForegroundColor Cyan
    
    if (Test-Path $ExtractedPath) {
        try {
            Remove-Item -Path $ExtractedPath -Recurse -Force
            Write-Host "✅ Временные файлы удалены: $ExtractedPath" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Не удалось удалить временные файлы: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "ℹ️  Временные файлы уже удалены" -ForegroundColor Gray
    }
}

function Start-Analysis {
    Write-Host "🚀 ЗАПУСК АВТОМАТИЗИРОВАННОГО АНАЛИЗА МОДОВ" -ForegroundColor Magenta
    Write-Host "Версия: 2.1 | Расширенное обнаружение хитбоксов" -ForegroundColor Gray
    Write-Host ""

    if (-not (Test-Path $InputDir)) {
        Write-Error "❌ Входная директория не существует: $InputDir"
        exit 1
    }

    $extractedPath = Extract-Classes
    $analysisResults = Analyze-Classes -SourceDirectory $extractedPath
    Cleanup-ExtractedClasses -ExtractedPath $extractedPath

    Write-Host "`n🎉 ВЕСЬ ПРОЦЕСС ЗАВЕРШЕН!" -ForegroundColor Green
    Write-Host "Для повторного анализа запустите скрипт с параметром -Overwrite" -ForegroundColor Gray
    
    return $analysisResults
}

# Запуск анализа
Start-Analysis
