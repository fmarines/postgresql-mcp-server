#!/bin/bash
# Dependency Fix Script
# Addresses issues found in dependency review

set -e

echo "🔍 PostgreSQL MCP Server - Dependency Fix Script"
echo "=================================================="
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Run this script from the project root."
    exit 1
fi

echo "📦 Current dependency versions:"
npm list @modelcontextprotocol/sdk --depth=0 || echo "  @modelcontextprotocol/sdk: Not installed"
npm list pg-query-stream --depth=0 || echo "  pg-query-stream: Not installed"
echo ""

# Ask user confirmation
read -p "Do you want to fix the dependencies? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "🔧 Fixing dependencies..."
echo ""

# Fix 1: Pin MCP SDK version
echo "1️⃣  Pinning @modelcontextprotocol/sdk version..."
CURRENT_VERSION=$(npm list @modelcontextprotocol/sdk --depth=0 2>/dev/null | grep @modelcontextprotocol/sdk | sed 's/.*@//' | sed 's/ .*//')

if [ -n "$CURRENT_VERSION" ]; then
    echo "   Current version: $CURRENT_VERSION"
    npm install @modelcontextprotocol/sdk@$CURRENT_VERSION --save-exact
    echo "   ✅ Pinned to version $CURRENT_VERSION"
else
    echo "   ⚠️  Could not detect current version. Please pin manually."
fi
echo ""

# Fix 2: Check pg-query-stream usage
echo "2️⃣  Checking pg-query-stream usage..."
if grep -rq "pg-query-stream\|QueryStream" src/; then
    echo "   ✅ pg-query-stream is used in code - keeping it"
else
    echo "   ⚠️  pg-query-stream not found in source code"
    read -p "   Remove pg-query-stream? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        npm uninstall pg-query-stream
        echo "   ✅ Removed pg-query-stream"
    else
        echo "   ⏭️  Skipped - keeping pg-query-stream"
    fi
fi
echo ""

# Run audit
echo "3️⃣  Running security audit..."
npm audit || echo "   ⚠️  Audit found issues - review with: npm audit"
echo ""

# Check for outdated packages
echo "4️⃣  Checking for outdated packages..."
npm outdated || echo "   ✅ All packages are up to date"
echo ""

# Rebuild
echo "5️⃣  Rebuilding project..."
npm run build
echo "   ✅ Build successful"
echo ""

echo "=================================================="
echo "✅ Dependency fixes completed!"
echo ""
echo "📝 Next steps:"
echo "   1. Review changes in package.json"
echo "   2. Test the application: npm test"
echo "   3. Commit changes: git add package.json package-lock.json"
echo "   4. Push to repository"
echo ""
echo "📄 For detailed review, see: DEPENDENCY_REVIEW.md"
