#!/bin/bash

# Setup script for template-repo
# This script copies shared resources from shared-repo to .github/shared

set -e  # Exit on any error

SHARED_REPO_URL="https://github.com/anboo44/shared-repo.git"
TEMP_DIR=".temp_shared_repo"
TARGET_DIR=".github/shared"

echo "🚀 Starting setup process..."

# Function to cleanup temporary directory
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        echo "🧹 Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Create .github directory if it doesn't exist
if [ ! -d ".github" ]; then
    echo "📁 Creating .github directory..."
    mkdir -p .github
fi

# Remove existing shared directory if it exists
if [ -d "$TARGET_DIR" ]; then
    echo "🗑️  Removing existing shared directory..."
    rm -rf "$TARGET_DIR"
fi

# Clone shared-repo to temporary directory
echo "📥 Cloning shared-repo..."
git clone --depth 1 "$SHARED_REPO_URL" "$TEMP_DIR"

# Copy shared directory to target location
echo "📋 Copying shared resources..."
cp -r "$TEMP_DIR/shared" "$TARGET_DIR"

# Copy secretlint config and setup
echo "🔐 Setting up secretlint..."
if [ -f "$TEMP_DIR/package.json" ]; then
    cp "$TEMP_DIR/package.json" "./"
fi

if [ -f "$TEMP_DIR/package-lock.json" ]; then
    cp "$TEMP_DIR/package-lock.json" "./"
fi

if [ -f "$TEMP_DIR/.secretlintrc.json" ]; then
    cp "$TEMP_DIR/.secretlintrc.json" "./"
fi

if [ -d "$TEMP_DIR/secretlint" ]; then
    cp -r "$TEMP_DIR/secretlint" "./"
fi

# Install secretlint dependencies
if [ -f "package.json" ]; then
    echo "📦 Installing secretlint dependencies..."
    npm install
fi

# Set up git hooks
echo "🔧 Setting up git hooks..."
HOOKS_DIR=".git/hooks"

# Create pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash

# Pre-commit hook to update shared resources and run secretlint

SHARED_REPO_URL="https://github.com/anboo44/shared-repo.git"
TEMP_DIR=".temp_shared_repo_hook"
TARGET_DIR=".github/shared"

echo "🔄 Updating shared resources before commit..."

# Function to cleanup
cleanup_hook() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup_hook EXIT

# Clone latest shared-repo
git clone --depth 1 "$SHARED_REPO_URL" "$TEMP_DIR" > /dev/null 2>&1

# Check if there are updates to shared resources
if [ -d "$TARGET_DIR" ]; then
    if ! diff -r "$TEMP_DIR/shared" "$TARGET_DIR" > /dev/null 2>&1; then
        echo "📦 Updating shared resources..."
        rm -rf "$TARGET_DIR"
        cp -r "$TEMP_DIR/shared" "$TARGET_DIR"
        git add "$TARGET_DIR"
        echo "✅ Shared resources updated and staged for commit"
    fi
else
    echo "📦 Setting up shared resources for the first time..."
    cp -r "$TEMP_DIR/shared" "$TARGET_DIR"
    git add "$TARGET_DIR"
    echo "✅ Shared resources added and staged for commit"
fi

# Update secretlint config if changed
secretlint_updated=false

if [ -f "$TEMP_DIR/.secretlintrc.json" ]; then
    if ! diff "$TEMP_DIR/.secretlintrc.json" ".secretlintrc.json" > /dev/null 2>&1; then
        cp "$TEMP_DIR/.secretlintrc.json" "./"
        secretlint_updated=true
        echo "📝 Updated secretlint config"
    fi
fi

if [ -d "$TEMP_DIR/secretlint" ] && [ -d "secretlint" ]; then
    if ! diff -r "$TEMP_DIR/secretlint" "secretlint" > /dev/null 2>&1; then
        rm -rf "secretlint"
        cp -r "$TEMP_DIR/secretlint" "./"
        secretlint_updated=true
        echo "� Updated secretlint rules"
    fi
fi

# Reinstall dependencies if secretlint config was updated
if [ "$secretlint_updated" = true ] && [ -f "package.json" ]; then
    echo "📦 Reinstalling dependencies due to secretlint updates..."
    npm install > /dev/null 2>&1
fi

# Run secretlint on staged files
if command -v npx > /dev/null 2>&1 && [ -f "package.json" ]; then
    echo "🔐 Running secretlint on staged files..."
    
    # Get list of staged files
    staged_files=$(git diff --cached --name-only --diff-filter=ACM)
    
    if [ -n "$staged_files" ]; then
        # Run secretlint on staged files
        if ! echo "$staged_files" | xargs npx secretlint; then
            echo "❌ Secretlint found potential secrets in your commit!"
            echo "Please review and fix the issues before committing."
            exit 1
        else
            echo "✅ Secretlint check passed"
        fi
    else
        echo "ℹ️ No staged files to check"
    fi
else
    echo "⚠️ Secretlint not available - skipping secret detection"
fi

EOF

# Make pre-commit hook executable
chmod +x "$HOOKS_DIR/pre-commit"

echo "✅ Setup completed successfully!"
echo ""
echo "📋 What was done:"
echo "  - Copied shared resources from shared-repo to $TARGET_DIR"
echo "  - Set up secretlint configuration and dependencies"
echo "  - Set up pre-commit hook to auto-update shared resources and run secretlint"
echo ""
echo "🎉 Your template-repo is now configured with shared resources and secret detection!"
echo "   The shared resources will be automatically updated before each commit."
echo "   Secretlint will check for secrets in your commits."