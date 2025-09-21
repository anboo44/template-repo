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

# Set up git hooks
echo "🔧 Setting up git hooks..."
HOOKS_DIR=".git/hooks"

# Create pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash

# Pre-commit hook to update shared resources from shared-repo

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

# Check if there are updates
if [ -d "$TARGET_DIR" ]; then
    # Compare directories and update if different
    if ! diff -r "$TEMP_DIR/shared" "$TARGET_DIR" > /dev/null 2>&1; then
        echo "📦 Updating shared resources..."
        rm -rf "$TARGET_DIR"
        cp -r "$TEMP_DIR/shared" "$TARGET_DIR"
        
        # Add updated files to git
        git add "$TARGET_DIR"
        echo "✅ Shared resources updated and staged for commit"
    else
        echo "✅ Shared resources are up to date"
    fi
else
    # First time setup
    echo "📦 Setting up shared resources for the first time..."
    cp -r "$TEMP_DIR/shared" "$TARGET_DIR"
    git add "$TARGET_DIR"
    echo "✅ Shared resources added and staged for commit"
fi

EOF

# Make pre-commit hook executable
chmod +x "$HOOKS_DIR/pre-commit"

echo "✅ Setup completed successfully!"
echo ""
echo "📋 What was done:"
echo "  - Copied shared resources from shared-repo to $TARGET_DIR"
echo "  - Set up pre-commit hook to auto-update shared resources"
echo ""
echo "🎉 Your template-repo is now configured with shared resources!"
echo "   The shared resources will be automatically updated before each commit."