$app    = Get-Content -LiteralPath 'garden-planner.html'        -Raw -Encoding UTF8
$manual = Get-Content -LiteralPath 'garden-planner-manual.html' -Raw -Encoding UTF8

function ToBase64Utf8($text) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    return [Convert]::ToBase64String($bytes)
}

$manualB64 = ToBase64Utf8($manual)
$iconB64   = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes('icon-512.png'))

# Inline the favicon as a data URI so this single-file build doesn't depend on icon-512.png alongside it
$app = $app -replace '<link rel="icon" type="image/png" href="icon-512\.png">', "<link rel=`"icon`" type=`"image/png`" href=`"data:image/png;base64,$iconB64`">"
$app = $app -replace '<link rel="apple-touch-icon" href="icon-512\.png">', "<link rel=`"apple-touch-icon`" href=`"data:image/png;base64,$iconB64`">"

# Replace the link to the separate manual file with a button that opens it inline instead
$app = $app -replace '<a class="btn secondary small" href="garden-planner-manual\.html"[^>]*>❓ <span class="btn-label">Manual</span></a>', '<button class="btn secondary small" onclick="openManualOverlay()">❓ <span class="btn-label">Manual</span></button>'

# Embed the whole manual as a base64 blob, shown in an isolated iframe (so its CSS/JS can't collide with the app's)
$manualOverlayHtml = @"
<div class="overlay" id="manualOverlay">
  <div class="modal" style="max-width:960px;width:94vw;height:88vh;padding:0;overflow:hidden;display:flex;flex-direction:column">
    <div style="display:flex;justify-content:flex-end;padding:10px 14px;border-bottom:1px solid var(--border)">
      <button class="btn secondary" onclick="closeManualOverlay()">Close</button>
    </div>
    <iframe id="manualFrame" style="flex:1;width:100%;border:none;background:#fff"></iframe>
  </div>
</div>
<script>
const MANUAL_HTML_B64 = "$manualB64";
let manualLoaded = false;
function openManualOverlay(){
  const ov = document.getElementById('manualOverlay');
  if(!manualLoaded){
    const bytes = Uint8Array.from(atob(MANUAL_HTML_B64), c => c.charCodeAt(0));
    document.getElementById('manualFrame').srcdoc = new TextDecoder('utf-8').decode(bytes);
    manualLoaded = true;
  }
  ov.classList.add('show');
}
function closeManualOverlay(){
  document.getElementById('manualOverlay').classList.remove('show');
}
</script>
</body>
"@

$app = $app.Replace('</body>', $manualOverlayHtml)

if (!(Test-Path 'dist')) { New-Item -ItemType Directory -Path 'dist' | Out-Null }
$out = 'dist\GardenPlanner.html'
Set-Content -LiteralPath $out -Value $app -Encoding UTF8
Write-Host "Done: $out"
