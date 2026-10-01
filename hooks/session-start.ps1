# SessionStart hook, Windows twin of hooks/session-start (bash).
#
# GitHub Copilot runs plugin hooks through PowerShell on Windows, where the bash
# script cannot run (issue #15: the quoted bash command reached PowerShell as a
# parse error). This script does the same job in PowerShell: decide whether the
# working project looks like FirstSpirit and emit the bootstrap skill, or a quiet
# one-liner, in Copilot's `{ "additionalContext": "..." }` shape.
#
# It is invoked as
#   powershell -NoProfile -ExecutionPolicy Bypass -File "<plugin root>/hooks/session-start.ps1"
# so the default Restricted execution policy of a Windows client does not block it.
#
# Keep the detection in step with hooks/session-start; that file holds the rationale.
#
# Keep this file pure ASCII. Windows PowerShell 5.1 reads a BOM-less script in the
# ANSI code page, where the UTF-8 bytes of an em dash end in 0x94, a curly double
# quote that PowerShell accepts as a string delimiter (issue #15, second report).
# Override with FIRSTSPIRIT_PROJECT=1 (always load) or 0 (never load).

$ErrorActionPreference = 'SilentlyContinue'

$PluginRoot = Split-Path -Parent $PSScriptRoot
$SkillFile  = Join-Path $PluginRoot 'skills\using-firstspirit-toolkit\SKILL.md'

$QuietLine    = "FirstSpirit AI Toolkit is available, but this does not look like a FirstSpirit project, so its skill index was not loaded. If the task turns out to involve FirstSpirit CMS, read $SkillFile for the list of skills. To always load it, set FIRSTSPIRIT_PROJECT=1."
$OptedOutLine = "FirstSpirit AI Toolkit is installed but disabled for this session via FIRSTSPIRIT_PROJECT=0. Do not load or mention it."

$Prune = @('node_modules', '.git', 'target', 'dist', 'build', '.gradle')

# Files under $Root up to $MaxDepth levels, skipping the pruned directories.
# Returns objects with Path, Name and Depth, counted like `find -maxdepth`: a file
# directly under $Root has Depth 1, so the `-le N` checks below mean the same as
# the bash twin's `fs_find N`.
function Get-ProjectFiles {
  param([string]$Root, [int]$MaxDepth, [int]$MaxFiles = 5000)
  $out = New-Object System.Collections.Generic.List[object]
  $queue = New-Object System.Collections.Generic.Queue[object]
  $queue.Enqueue(@{ Dir = $Root; Depth = 0 })
  while ($queue.Count -gt 0 -and $out.Count -lt $MaxFiles) {
    $cur = $queue.Dequeue()
    $items = Get-ChildItem -LiteralPath $cur.Dir -Force -ErrorAction SilentlyContinue
    foreach ($it in $items) {
      if ($it.PSIsContainer) {
        if ($cur.Depth + 1 -lt $MaxDepth -and $Prune -notcontains $it.Name) {
          $queue.Enqueue(@{ Dir = $it.FullName; Depth = $cur.Depth + 1 })
        }
      } else {
        $out.Add([pscustomobject]@{ Path = $it.FullName; Name = $it.Name; Depth = $cur.Depth + 1 })
        if ($out.Count -ge $MaxFiles) { return $out }
      }
    }
  }
  return $out
}

function Test-FileMatches {
  param([string]$Path, [string]$Pattern)
  $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
  return ($null -ne $text -and $text -match $Pattern)
}

function Test-FirstSpiritProject {
  # 1) Explicit override wins in both directions.
  switch -Regex ($env:FIRSTSPIRIT_PROJECT) {
    '^(1|true|yes)$'  { return $true }
    '^(0|false|no)$'  { return $false }
  }

  # 2) Search root: the git top-level if there is one, else the project dir.
  $start = if ($env:CLAUDE_PROJECT_DIR) { ($env:CLAUDE_PROJECT_DIR -replace '/', '\') } else { (Get-Location).Path }
  $root  = $start
  $top   = & git -C $start rev-parse --show-toplevel 2>$null
  if ($LASTEXITCODE -eq 0 -and $top) { $root = ($top -replace '/', '\') }
  if (-not (Test-Path -LiteralPath $root)) { return $false }

  # 3) Explicit marker or the Cloud pipeline descriptor, walking up from start to root.
  $d = $start
  for ($i = 0; $i -lt 8; $i++) {
    foreach ($m in '.firstspirit', 'fs-project.yaml', 'fsproject.yaml') {
      if (Test-Path -LiteralPath (Join-Path $d $m)) { return $true }
    }
    if ($d -ieq $root) { break }
    $parent = Split-Path -Parent $d
    if (-not $parent -or $parent -eq $d) { break }
    $d = $parent
  }

  $files = Get-ProjectFiles -Root $root -MaxDepth 4

  # 4) Shallow scan for the same markers, plus server/CLI config and module archives.
  $markers = @('.firstspirit', 'fs-project.yaml', 'fsproject.yaml', 'fs-server.conf', 'fs-cli.yaml')
  foreach ($f in $files) {
    if ($f.Depth -le 3 -and ($markers -contains $f.Name -or $f.Name -like '*.fsm')) { return $true }
  }

  # 5) External-sync export signature.
  foreach ($f in $files) {
    if ($f.Depth -le 4 -and ($f.Name -eq 'FS_References.txt' -or $f.Name -eq 'FS_Info.txt')) { return $true }
  }

  # 6) A module descriptor that actually names FirstSpirit.
  $n = 0
  foreach ($f in $files) {
    if ($f.Depth -le 4 -and ($f.Name -eq 'module.xml' -or $f.Name -eq 'module-isolated.xml')) {
      if (Test-FileMatches $f.Path '(?i)de\.espirit|firstspirit') { return $true }
      if (++$n -ge 20) { break }
    }
  }

  # 7) A build file that depends on the FirstSpirit Access API / isolated runtime.
  $n = 0
  foreach ($f in $files) {
    if ($f.Depth -le 3 -and ($f.Name -eq 'pom.xml' -or $f.Name -eq 'build.gradle' -or $f.Name -eq 'build.gradle.kts')) {
      if (Test-FileMatches $f.Path '(?i)fs-isolated-runtime|fs-isolated-client|fs-access|de\.espirit\.firstspirit') { return $true }
      if (++$n -ge 20) { break }
    }
  }

  # 8) A decoupled frontend on the FSXA stack.
  $n = 0
  foreach ($f in $files) {
    if ($f.Depth -le 3 -and $f.Name -eq 'package.json') {
      if (Test-FileMatches $f.Path '"(fsxa-api|fsxa-pattern-library|fsxa-nuxt-ui|fsxa-nextjs)"') { return $true }
      if (++$n -ge 20) { break }
    }
  }

  return $false
}

# --- Choose content -----------------------------------------------------------

if (Test-FirstSpiritProject) {
  if (Test-Path -LiteralPath $SkillFile) {
    $body = Get-Content -LiteralPath $SkillFile -Raw -Encoding UTF8
    if ($null -ne $body) {
      # Same text as the bash twin; the em dash and ellipsis are built from code points
      # to keep this file ASCII.
      $content = "$body`nToolkit root: $PluginRoot $([char]0x2014) resolve any ``skills/$([char]0x2026)`` path in this document relative to that directory."
    } else {
      $content = "FirstSpirit AI Toolkit: bootstrap skill not found at $SkillFile."
    }
  } else {
    $content = "FirstSpirit AI Toolkit: bootstrap skill not found at $SkillFile."
  }
} elseif ($env:FIRSTSPIRIT_PROJECT -match '^(0|false|no)$') {
  $content = $OptedOutLine
} else {
  $content = $QuietLine
}

# --- Emit -----------------------------------------------------------------------
# Same envelope selection as the bash twin, same order: Copilot and Cursor both set
# CLAUDE_PLUGIN_ROOT, so each harness's own variable is tested first and the generic
# Claude variable last. ConvertTo-Json escapes the string, so the skill text needs no
# hand-rolled escaping here.
if ($env:COPILOT_PLUGIN_ROOT -or $env:COPILOT_AGENT_SESSION_ID) {
  $payload = @{ additionalContext = $content } | ConvertTo-Json -Compress -Depth 2
} elseif ($env:CURSOR_PLUGIN_ROOT) {
  $payload = @{ additional_context = $content } | ConvertTo-Json -Compress -Depth 2
} elseif ($env:CLAUDE_PLUGIN_ROOT) {
  $payload = @{ hookSpecificOutput = @{ hookEventName = 'SessionStart'; additionalContext = $content } } | ConvertTo-Json -Compress -Depth 3
} else {
  $payload = @{ additionalContext = $content } | ConvertTo-Json -Compress -Depth 2
}
# Escape every non-ASCII character as \uXXXX so the output does not depend on the
# console code page, which on Windows is rarely UTF-8.
$payload = [regex]::Replace($payload, '[^\x00-\x7F]', { param($m) '\u{0:x4}' -f [int][char]$m.Value })
[Console]::Out.Write($payload + "`n")
exit 0
