# Regenerate Qurany test reports (backend + Flutter) and refresh summary artifacts.
$ErrorActionPreference = "Stop"
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$Backend = Join-Path $Root "backend"
$Flutter = Join-Path $Root "flutter_app"
$Docs = Join-Path $Root "docs\test_report"

Write-Host "=== Backend tests ===" -ForegroundColor Cyan
Set-Location $Backend
pip install pytest-html pytest-cov -q
New-Item -ItemType Directory -Force -Path reports | Out-Null
python -m pytest tests/ -v --tb=short `
  --html=reports/pytest_report.html --self-contained-html `
  --junitxml=reports/junit.xml `
  --cov=src --cov-report=html:reports/coverage_html --cov-report=term `
  2>&1 | Tee-Object -FilePath reports/pytest_console.txt

Write-Host "`n=== Flutter tests ===" -ForegroundColor Cyan
Set-Location $Flutter
New-Item -ItemType Directory -Force -Path test_reports | Out-Null
flutter test --reporter expanded --coverage 2>&1 | Tee-Object -FilePath test_reports/flutter_console.txt

Write-Host "`n=== Summary ===" -ForegroundColor Green
Write-Host "Open: $Docs\QURANY_TEST_REPORT.html"
Write-Host "Detail: $Backend\reports\pytest_report.html"
Write-Host "Coverage: $Backend\reports\coverage_html\index.html"
Write-Host "JSON (for agents): $Docs\test_results.json"
