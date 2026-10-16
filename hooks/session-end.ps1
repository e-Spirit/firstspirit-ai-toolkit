# SessionEnd hook (PowerShell twin of hooks/session-end): write a local feedback note
# when a session used the toolkit. Off by default; FIRSTSPIRIT_FEEDBACK=1 turns it on.
#
# Same contract as the bash hook: the note holds the toolkit version, the assistant, the
# names of toolkit skills and reference files the session touched, and empty sections for
# the person. No prompts, answers, file contents or project names. Nothing is sent.
# The folder is .firstspirit-feedback, not .firstspirit (that name is a project marker).
# Every failure path exits 0. Keep this file ASCII: Windows PowerShell 5.1 reads a BOM-less
# script in the ANSI code page.

$ErrorActionPreference = 'SilentlyContinue'

$flag = $env:FIRSTSPIRIT_FEEDBACK
if (@('1', 'true', 'yes') -notcontains "$flag".ToLower()) { exit 0 }

$pluginRoot = Split-Path -Parent $PSScriptRoot

$raw = ''
try { $raw = [Console]::In.ReadToEnd() } catch { exit 0 }
if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }

$in = $null
try { $in = $raw | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $in) { exit 0 }

$transcript = [string]$in.transcript_path
$workdir = [string]$in.cwd
$reason = ([string]$in.reason) -replace '[^a-z_]', '?'
if ($reason.Length -gt 40) { $reason = $reason.Substring(0, 40) }
if ([string]::IsNullOrEmpty($transcript) -or -not (Test-Path -LiteralPath $transcript)) { exit 0 }
if ([string]::IsNullOrEmpty($workdir) -or -not (Test-Path -LiteralPath $workdir)) {
    $workdir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }
}
if (-not (Test-Path -LiteralPath $workdir)) { exit 0 }

# What the session touched: only Read and Skill tool calls, only toolkit names and paths.
$names = New-Object System.Collections.Generic.SortedSet[string]
$files = New-Object System.Collections.Generic.SortedSet[string]
$callLines = Select-String -LiteralPath $transcript -Pattern '"name": ?"(Read|Skill)"' | ForEach-Object { $_.Line }
foreach ($line in $callLines) {
    foreach ($m in [regex]::Matches($line, 'skills/(templating|project|deployment)/(firstspirit-[a-z0-9-]+)')) {
        [void]$names.Add($m.Groups[2].Value)
    }
    foreach ($m in [regex]::Matches($line, '"skill": ?"(?:firstspirit-ai-toolkit:)?(firstspirit-[a-z0-9-]+)"')) {
        [void]$names.Add($m.Groups[1].Value)
    }
    if ($line -match '"name": ?"Read"') {
        foreach ($m in [regex]::Matches($line, 'skills/(?:templating|project|deployment)/firstspirit-[a-z0-9-]+/(?:SKILL\.md|references/[A-Za-z0-9._/-]+\.md)')) {
            [void]$files.Add($m.Value)
        }
    }
}
if ($names.Count -eq 0) { exit 0 }

$version = 'unknown'
$pkg = Join-Path $pluginRoot 'package.json'
if (Test-Path -LiteralPath $pkg) {
    $m = [regex]::Match((Get-Content -LiteralPath $pkg -Raw), '"version"\s*:\s*"([^"]*)"')
    if ($m.Success) { $version = $m.Groups[1].Value }
}

$harness = 'unknown'
if ($env:CURSOR_PLUGIN_ROOT) { $harness = 'Cursor' }
elseif ($env:COPILOT_PLUGIN_ROOT -or $env:COPILOT_AGENT_SESSION_ID) { $harness = 'GitHub Copilot' }
elseif ($env:CLAUDE_PLUGIN_ROOT) { $harness = 'Claude Code' }

$stamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'
$day = $stamp.Substring(0, 10)
$skillList = ($names | ForEach-Object { "- $_" }) -join "`n"
$fileList = if ($files.Count -gt 0) { (($files | Select-Object -First 40) | ForEach-Object { "- $_" }) -join "`n" } else { '- (none read by name)' }
if ([string]::IsNullOrEmpty($reason)) { $reason = 'unknown' }

$dir = Join-Path $workdir '.firstspirit-feedback'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$ignore = Join-Path $dir '.gitignore'
$utf8 = New-Object System.Text.UTF8Encoding($false)
if (-not (Test-Path -LiteralPath $ignore)) { [System.IO.File]::WriteAllText($ignore, "*`n", $utf8) }

$out = Join-Path $dir "firstspirit-feedback-$stamp.md"
$text = @"
# FirstSpirit AI Toolkit: feedback note

Written on your machine by the toolkit's session-end hook. Nothing has been sent anywhere.
It holds no prompts, no answers, no file contents and no project names.

| | |
|---|---|
| Toolkit version | $version |
| Assistant | $harness |
| Date | $day |
| Session ended | $reason |

## Skills this session used

$skillList

Reference files read (names only):

$fileList

## What happened

_(Write here what was wrong, unclear or missing, in your own words. One sentence is enough. Do not paste project content, customer names, addresses or credentials.)_

## What you expected

_(Write here what you expected instead.)_

## Category and severity (optional)

Category: wrong, unclear, missing, skill did not trigger, other
Severity: blocker, major, minor

<!-- end of report: everything below stays on your machine -->

## Handing it in

Read the text above once before it goes anywhere. Issues on the toolkit's GitHub repository are public.

- Open an issue at https://github.com/e-Spirit/firstspirit-ai-toolkit/issues and paste the report: the text above the line "end of report", not this section.
- With the GitHub CLI installed and signed in, you can also run: gh issue create --repo e-Spirit/firstspirit-ai-toolkit --title "Skill feedback"  (it opens an editor; paste the report there).

## For an AI assistant

Only when the person asks you to hand this feedback in:

1. Fill the sections above from this conversation, in the person's own words, and tell the person what you wrote. Leave out project content, customer names, addresses and credentials.
2. Show the person the exact text you would post, and say it will be public on the toolkit's GitHub repository.
3. Post it with gh issue create only if the person then says yes. Never post on your own initiative.
4. If the GitHub CLI is missing or not signed in, give the person the manual route above. Do not ask for tokens.
"@
[System.IO.File]::WriteAllText($out, $text, $utf8)
[Console]::Error.WriteLine("FirstSpirit AI Toolkit: feedback note written to $out")
exit 0
