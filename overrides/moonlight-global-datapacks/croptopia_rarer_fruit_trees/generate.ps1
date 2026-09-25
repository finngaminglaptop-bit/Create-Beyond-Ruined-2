# =====================================================================
#  Croptopia - Rarer Fruit Trees - datapack generator
# =====================================================================
#  This script rebuilds data/croptopia/worldgen/placed_feature/*.json
#  from the untouched vanilla-Croptopia copies in originals/, scaling
#  each tree's spawn rarity.
#
#  TO CHANGE THE RARITY: edit the numbers below, save, then re-run this
#  script (double-click it, or run `./generate.ps1` from PowerShell).
#  It always regenerates from originals/, so you can raise or lower
#  the numbers as many times as you like without compounding errors.
#
#  Croptopia's 27 trees use one of two placement mechanisms, and that
#  (not the trunk type) is what actually determines how a given
#  multiplier "feels" in-game, so trees are grouped by mechanism:
#
#    - RarityFilterMultiplier: the 21 trees that use a simple 1-in-N
#      "rarity_filter" (apple, apricot, avocado, banana, cherry, date,
#      dragonfruit, fig, grapefruit, kumquat, lemon, lime, mango,
#      nectarine, nutmeg, orange, peach, pear, persimmon, plum,
#      starfruit).
#    - WeightedListMultiplier: the 6 trees that roll between "no tree"
#      and "a small cluster" (almond, cashew, cinnamon, coconut,
#      pecan, walnut).
#
#  The script figures out which mechanism each file uses automatically
#  - you don't need to maintain any tree name lists.
#
#  Multiplier meaning (applies to both tiers):
#    1   = same rarity as vanilla Croptopia
#    10  = ten times as rare
#    50  = fifty times as rare
#    0.5 = TWICE AS COMMON as vanilla (values below 1 work too)
#
#  Current values (50 / 10) were picked to match how apple and almond
#  felt when the previous tiered version of this pack was tested in
#  Create Beyond Ruin: apple (rarity_filter) at 50x and almond
#  (weighted-list) at 10x both felt like "good" rarity, so every tree
#  using that same mechanism now gets that same multiplier.
# =====================================================================

$RarityFilterMultiplier = 50
$WeightedListMultiplier = 10

# ---------------------------------------------------------------------

$root       = $PSScriptRoot
$srcDir     = Join-Path $root "originals"
$outDir     = Join-Path $root "data\croptopia\worldgen\placed_feature"

if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

$files = Get-ChildItem -Path $srcDir -Filter "*.json"
$rarityFilterCount = 0
$weightedListCount  = 0

foreach ($file in $files) {
    $json = Get-Content -Raw -Path $file.FullName | ConvertFrom-Json

    foreach ($entry in $json.placement) {

        if ($entry.type -eq "minecraft:rarity_filter") {
            # Simple case: 1-in-N chance. Bigger N = rarer.
            $newChance = [Math]::Max(1, [Math]::Round($entry.chance * $RarityFilterMultiplier))
            $entry.chance = $newChance
            $rarityFilterCount++
        }
        elseif ($entry.type -eq "minecraft:count" -and $entry.count.type -eq "minecraft:weighted_list") {
            # Weighted-list case: a "low" outcome (usually 0 saplings)
            # competing against a "high" outcome (a small cluster). We
            # keep the high outcome's weight fixed and grow the low
            # outcome's weight so the high outcome becomes exactly
            # $WeightedListMultiplier times less likely.
            $dist = $entry.count.distribution
            $sorted = $dist | Sort-Object data
            $low  = $sorted[0]
            $high = $sorted[-1]
            $total = [double]$low.weight + [double]$high.weight
            $newLowWeight = [Math]::Max(1, [Math]::Round(($WeightedListMultiplier * $total) - $high.weight))
            $low.weight = $newLowWeight
            $weightedListCount++
        }
    }

    $outPath = Join-Path $outDir $file.Name
    $jsonText = $json | ConvertTo-Json -Depth 20
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($outPath, $jsonText, $utf8NoBom)
}

Write-Host "Regenerated $($files.Count) placed_feature files:"
Write-Host "  rarity_filter tier ($RarityFilterMultiplier x): $rarityFilterCount files"
Write-Host "  weighted_list tier ($WeightedListMultiplier x): $weightedListCount files"
