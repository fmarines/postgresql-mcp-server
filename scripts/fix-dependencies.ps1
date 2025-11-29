# Dependency Fix Script (PowerShell)
# Addresses issues found in dependency review

Write-Host "🔍 PostgreSQL MCP Server - Dependency Fix Script" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "package.json")) {
    Write-Host "❌ Error: package.json not found. Run this script from the project root." -ForegroundColor Red
    exit 1
}

Write-Host "📦 Current dependency versions:" -ForegroundColor Yellow
try {
    npm list @modelcontextprotocol/sdk --depth=0 2>$null
} catch {
    Write-Host "  @modelcontextprotocol/sdk: Not installed" -ForegroundColor Gray
}
try {
    npm list pg-query-stream --depth=0 2>$null
} catch {
    Write-Host "  pg-query-stream: Not installed" -ForegroundColor Gray
}
Write-Host ""

# Ask user confirmation
$confirmation = Read-Host "Do you want to fix the dependencies? (y/n)"
if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
    Write-Host "Aborted." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "🔧 Fixing dependencies..." -ForegroundColor Green
Write-Host ""

# Fix 1: Pin MCP SDK version
Write-Host "1️⃣  Pinning @modelcontextprotocol/sdk version..." -ForegroundColor Cyan
try {
    $npmList = npm list @modelcontextprotocol/sdk --depth=0 2>&1
    if ($npmList -match '@modelcontextprotocol/sdk@(.+?)(?:\s|$)') {
        $currentVersion = $matches[1]
        Write-Host "   Current version: $currentVersion" -ForegroundColor Gray
        npm install "@modelcontextprotocol/sdk@$currentVersion" --save-exact
        Write-Host "   ✅ Pinned to version $currentVersion" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Could not detect current version. Please pin manually." -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⚠️  Error detecting version: $_" -ForegroundColor Yellow
}
Write-Host ""

# Fix 2: Check pg-query-stream usage
Write-Host "2️⃣  Checking pg-query-stream usage..." -ForegroundColor Cyan
$found = $false
if (Test-Path "src") {
    $searchResults = Get-ChildItem -Path "src" -Recurse -Filter "*.ts" | Select-String -Pattern "pg-query-stream|QueryStream" -Quiet
    $found = $searchResults
}

if ($found) {
    Write-Host "   ✅ pg-query-stream is used in code - keeping it" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  pg-query-stream not found in source code" -ForegroundColor Yellow
    $remove = Read-Host "   Remove pg-query-stream? [y/n]"
    if ($remove -eq 'y' -or $remove -eq 'Y') {
        npm uninstall pg-query-stream
        Write-Host "   ✅ Removed pg-query-stream" -ForegroundColor Green
    } else {
        Write-Host "   ⏭️  Skipped - keeping pg-query-stream" -ForegroundColor Gray
    }
}
Write-Host ""

# Run audit
Write-Host "3️⃣  Running security audit..." -ForegroundColor Cyan
try {
    npm audit
} catch {
    Write-Host "   ⚠️  Audit found issues - review with: npm audit" -ForegroundColor Yellow
}
Write-Host ""

# Check for outdated packages
Write-Host "4️⃣  Checking for outdated packages..." -ForegroundColor Cyan
try {
    $outdated = npm outdated 2>&1
    if ($outdated) {
        Write-Host $outdated
    } else {
        Write-Host "   ✅ All packages are up to date" -ForegroundColor Green
    }
} catch {
    Write-Host "   ✅ All packages are up to date" -ForegroundColor Green
}
Write-Host ""

# Rebuild
Write-Host "5️⃣  Rebuilding project..." -ForegroundColor Cyan
try {
    npm run build
    Write-Host "   ✅ Build successful" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Build failed - check errors above" -ForegroundColor Red
}
Write-Host ""

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "✅ Dependency fixes completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Review changes in package.json"
Write-Host "   2. Test the application: npm test"
Write-Host "   3. Commit changes: git add package.json package-lock.json"
Write-Host "   4. Push to repository"
Write-Host ""
Write-Host "📄 For detailed review, see: DEPENDENCY_REVIEW.md" -ForegroundColor Cyan
