# migrate_services.ps1
# Migrates messaging services from lib/services/ to lib/features/messages/data/
# Performs full global import replacement across all .dart files, then deletes originals.

$libRoot = "f:\oasis\lib"
$srcServices = "$libRoot\services"
$dstData     = "$libRoot\features\messages\data"

# ── 1. COPY FILES ──────────────────────────────────────────────────────────────

$copies = @(
  @{ Src = "$srcServices\messaging_service.dart";         Dst = "$dstData\messaging_service.dart" },
  @{ Src = "$srcServices\conversation_service.dart";      Dst = "$dstData\conversation_service.dart" },
  @{ Src = "$srcServices\message_operations_service.dart";Dst = "$dstData\message_operations_service.dart" },
  @{ Src = "$srcServices\chat_decryption_service.dart";   Dst = "$dstData\chat_decryption_service.dart" },
  @{ Src = "$srcServices\chat_media_service.dart";        Dst = "$dstData\chat_media_service.dart" },
  @{ Src = "$srcServices\encryption_service.dart";        Dst = "$dstData\encryption_service.dart" },
  @{ Src = "$srcServices\signal\signal_service.dart";     Dst = "$dstData\signal\signal_service.dart" },
  @{ Src = "$srcServices\signal\signal_store.dart";       Dst = "$dstData\signal\signal_store.dart" }
)

# Ensure destination signal subfolder exists
New-Item -ItemType Directory -Force -Path "$dstData\signal" | Out-Null

foreach ($c in $copies) {
  Copy-Item -Path $c.Src -Destination $c.Dst -Force
  Write-Host "Copied: $($c.Src.Replace('f:\oasis\lib\','')) → $($c.Dst.Replace('f:\oasis\lib\',''))"
}

# ── 2. GLOBAL IMPORT REPLACEMENTS ─────────────────────────────────────────────
# Order matters: longer/more-specific paths first to avoid partial replacement.

$replacements = [ordered]@{
  "package:oasis/services/message_operations_service.dart" = "package:oasis/features/messages/data/message_operations_service.dart"
  "package:oasis/services/chat_decryption_service.dart"    = "package:oasis/features/messages/data/chat_decryption_service.dart"
  "package:oasis/services/chat_media_service.dart"         = "package:oasis/features/messages/data/chat_media_service.dart"
  "package:oasis/services/conversation_service.dart"       = "package:oasis/features/messages/data/conversation_service.dart"
  "package:oasis/services/messaging_service.dart"          = "package:oasis/features/messages/data/messaging_service.dart"
  "package:oasis/services/encryption_service.dart"         = "package:oasis/features/messages/data/encryption_service.dart"
  "package:oasis/services/signal/signal_service.dart"      = "package:oasis/features/messages/data/signal/signal_service.dart"
  "package:oasis/services/signal/signal_store.dart"        = "package:oasis/features/messages/data/signal/signal_store.dart"
}

$dartFiles = Get-ChildItem -Path $libRoot -Filter "*.dart" -Recurse

$totalReplaced = 0
foreach ($file in $dartFiles) {
  $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
  $original = $content
  foreach ($old in $replacements.Keys) {
    $new = $replacements[$old]
    $content = $content -replace [regex]::Escape($old), $new
  }
  if ($content -ne $original) {
    Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
    $totalReplaced++
    Write-Host "  Updated imports: $($file.FullName.Replace('f:\oasis\lib\','lib\'))"
  }
}
Write-Host "`n✅ Import replacement done. $totalReplaced files updated."

# ── 3. DELETE ORIGINALS ────────────────────────────────────────────────────────

$toDelete = @(
  "$srcServices\messaging_service.dart",
  "$srcServices\conversation_service.dart",
  "$srcServices\message_operations_service.dart",
  "$srcServices\chat_decryption_service.dart",
  "$srcServices\chat_media_service.dart",
  "$srcServices\encryption_service.dart",
  "$srcServices\signal\signal_service.dart",
  "$srcServices\signal\signal_store.dart"
)

foreach ($f in $toDelete) {
  if (Test-Path $f) {
    Remove-Item $f -Force
    Write-Host "Deleted: $($f.Replace('f:\oasis\lib\','lib\'))"
  }
}

# Remove signal dir if now empty
$signalDir = "$srcServices\signal"
if ((Test-Path $signalDir) -and ((Get-ChildItem $signalDir).Count -eq 0)) {
  Remove-Item $signalDir -Force
  Write-Host "Removed empty dir: lib\services\signal\"
}

Write-Host "`n✅ Migration complete."
