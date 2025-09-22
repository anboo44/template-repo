#!/bin/bash

# Setup Script cho Template Repository
# Thiết lập shared resources và secretlint integration

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SHARED_REPO_URL="https://github.com/anboo44/shared-repo"
SHARED_REPO_DIR="$HOME/.shared-repo"
TEMPLATE_SHARED_DIR=".github/shared"
TEMPLATE_SECRETLINT_DIR=".vscode"
CUSTOM_CONFIG_FILE="$TEMPLATE_SECRETLINT_DIR/custom.secretlintrc.json"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Node.js version
check_node_version() {
    print_status "Kiểm tra Node.js version..."
    
    if ! command_exists node; then
        print_warning "Node.js chưa được cài đặt"
        return 1
    fi
    
    local node_version=$(node --version | sed 's/v//')
    local major_version=$(echo $node_version | cut -d. -f1)
    
    if [ "$major_version" -lt 20 ]; then
        print_warning "Node.js version hiện tại: v$node_version (cần ≥v20)"
        return 1
    fi
    
    print_success "Node.js version: v$node_version (OK)"
    return 0
}

# Function to install Node.js using nvm
install_nodejs() {
    print_status "Cài đặt Node.js v20..."
    
    # Check if nvm exists
    if [ ! -s "$HOME/.nvm/nvm.sh" ]; then
        print_status "Cài đặt nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        
        # Source nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    else
        # Source nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
    
    # Install and use Node.js v20
    nvm install 20
    nvm use 20
    nvm alias default 20
    
    print_success "Node.js v20 đã được cài đặt"
}

# Function to clone or update shared repository
setup_shared_repo() {
    print_status "Thiết lập shared repository..."
    
    if [ -d "$SHARED_REPO_DIR" ]; then
        print_status "Cập nhật shared repository..."
        cd "$SHARED_REPO_DIR"
        
        # Get the default branch name
        DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
        
        # Try to pull from the default branch, fallback to master if main doesn't exist
        if ! git pull origin "$DEFAULT_BRANCH" 2>/dev/null; then
            print_warning "Không thể pull từ branch '$DEFAULT_BRANCH', thử branch 'master'..."
            if ! git pull origin master 2>/dev/null; then
                print_warning "Không thể pull từ branch 'master', thử branch 'main'..."
                if ! git pull origin main 2>/dev/null; then
                    print_error "Không thể pull từ remote repository"
                    cd - > /dev/null
                    return 1
                fi
            fi
        fi
        
        cd - > /dev/null
    else
        print_status "Clone shared repository..."
        if ! git clone "$SHARED_REPO_URL" "$SHARED_REPO_DIR"; then
            print_error "Không thể clone repository từ $SHARED_REPO_URL"
            return 1
        fi
    fi
    
    print_success "Shared repository đã sẵn sàng tại $SHARED_REPO_DIR"
}

# Function to copy shared resources
copy_shared_resources() {
    print_status "Sao chép shared resources..."
    
    # Create .github directory if not exists
    mkdir -p .github
    
    # Remove existing shared directory and copy new one
    if [ -d "$TEMPLATE_SHARED_DIR" ]; then
        rm -rf "$TEMPLATE_SHARED_DIR"
    fi
    
    cp -r "$SHARED_REPO_DIR/shared" "$TEMPLATE_SHARED_DIR"
    print_success "Shared resources đã được sao chép vào $TEMPLATE_SHARED_DIR"
}

# Function to create secretlint directory and custom config
create_secretlint_config() {
    print_status "Tạo secretlint configuration..."
    
    # Create .vscode directory
    mkdir -p "$TEMPLATE_SECRETLINT_DIR"
    
    # Create custom.secretlintrc.json if not exists
    if [ ! -f "$CUSTOM_CONFIG_FILE" ]; then
        cat > "$CUSTOM_CONFIG_FILE" << 'EOF'
{
  "rules": [
    {
      "id": "@secretlint/secretlint-rule-pattern",
      "options": {
        "patterns": [
          {
            "name": "Custom API Key Pattern",
            "pattern": "/custom[_-]?api[_-]?key\\s*[=:]\\s*['\"][^'\"]+['\"]/gi",
            "message": "Custom API key detected"
          }
        ]
      }
    }
  ]
}
EOF
        print_success "Custom secretlint config đã được tạo tại $CUSTOM_CONFIG_FILE"
    else
        print_status "Custom secretlint config đã tồn tại"
    fi
}

# Function to setup secretlint in shared directory
setup_secretlint_home() {
    print_status "Thiết lập secretlint từ shared repository..."
    
    if [ ! -d "$SHARED_REPO_DIR/secretlint" ]; then
        print_error "Secretlint folder không tồn tại trong shared repository"
        return 1
    fi
    
    # Install dependencies in shared repo secretlint folder
    cd "$SHARED_REPO_DIR/secretlint"
    npm install
    
    # Create initial merged config
    print_status "Tạo initial secretlint config..."
    if [ -f "$OLDPWD/$CUSTOM_CONFIG_FILE" ]; then
        node merge.js "$OLDPWD/$CUSTOM_CONFIG_FILE"
    else
        node merge.js
    fi
    
    # Verify merged config was created
    if [ -f ".secretlintrc.json" ]; then
        print_success "Initial secretlint config đã được tạo"
    else
        print_error "Không thể tạo initial config"
        cd - > /dev/null
        return 1
    fi
    
    cd - > /dev/null
    
    print_success "Secretlint đã được thiết lập từ shared repository"
}

# Function to create git pre-commit hook
create_git_hook() {
    print_status "Tạo git pre-commit hook..."
    
    # Check if this is a git repository
    if [ ! -d ".git" ]; then
        print_error "Đây không phải là git repository"
        return 1
    fi
    
    # Create hooks directory if not exists
    mkdir -p .git/hooks
    
    # Create pre-commit hook
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

# Pre-commit hook for secretlint checking
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[PRE-COMMIT]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PRE-COMMIT]${NC} $1"
}

print_error() {
    echo -e "${RED}[PRE-COMMIT]${NC} $1"
}

# Configuration
SHARED_REPO_DIR="$HOME/.shared-repo"
TEMPLATE_SHARED_DIR=".github/shared"
CUSTOM_CONFIG_FILE=".vscode/custom.secretlintrc.json"

print_status "Chạy pre-commit checks..."

# 1. Update shared resources
print_status "Cập nhật shared resources..."
if [ -d "$SHARED_REPO_DIR" ]; then
    cd "$SHARED_REPO_DIR"
    
    # Get the default branch name
    DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
    
    # Try to pull from the default branch, fallback to master/main
    if ! git pull origin "$DEFAULT_BRANCH" > /dev/null 2>&1; then
        if ! git pull origin master > /dev/null 2>&1; then
            git pull origin main > /dev/null 2>&1 || true
        fi
    fi
    
    cd - > /dev/null
    
    # Copy updated shared resources
    if [ -d "$TEMPLATE_SHARED_DIR" ]; then
        rm -rf "$TEMPLATE_SHARED_DIR"
    fi
    cp -r "$SHARED_REPO_DIR/shared" "$TEMPLATE_SHARED_DIR"
    print_success "Shared resources đã được cập nhật"
else
    print_error "Shared repository không tồn tại tại $SHARED_REPO_DIR"
    exit 1
fi

# 2. Merge secretlint configurations
print_status "Merge secretlint configurations..."
if [ ! -d "$SHARED_REPO_DIR/secretlint" ]; then
    print_error "Secretlint không tồn tại trong shared repository"
    exit 1
fi

cd "$SHARED_REPO_DIR/secretlint"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    npm install > /dev/null 2>&1
fi

# Run merge.js
if [ -f "$OLDPWD/$CUSTOM_CONFIG_FILE" ]; then
    node merge.js "$OLDPWD/$CUSTOM_CONFIG_FILE"
else
    node merge.js
fi

# Verify merged config was created
if [ -f ".secretlintrc.json" ]; then
    print_success "Merged secretlint config đã được tạo"
else
    print_error "Không thể tạo merged config"
    exit 1
fi

cd - > /dev/null

# 3. Get staged files for secretlint checking
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED_FILES" ]; then
    print_status "Không có file nào được staged"
    exit 0
fi

print_status "Kiểm tra secrets trong staged files..."

# 4. Run secretlint on staged files only
TEMP_DIR=$(mktemp -d)
FAILED=false

for file in $STAGED_FILES; do
    if [ -f "$file" ]; then
        # Skip secretlint config files to avoid false positives
        case "$file" in
            *secretlintrc* | *.secretlintrc.json | .secretlintignore)
                print_status "Skipping secretlint config file: $file"
                continue
                ;;
        esac
        
        # Create temp file in secretlint directory for scanning
        SECRETLINT_TEMP_DIR="$SHARED_REPO_DIR/secretlint/temp_scan"
        mkdir -p "$SECRETLINT_TEMP_DIR/$(dirname "$file")"
        git show ":$file" > "$SECRETLINT_TEMP_DIR/$file" 2>/dev/null || continue
        
        # Run secretlint on the file from shared-repo directory
        cd "$SHARED_REPO_DIR/secretlint"
        if ! npx secretlint "temp_scan/$file" --secretlintrc ".secretlintrc.json" > /dev/null 2>&1; then
            print_error "Secrets detected in: $file"
            npx secretlint "temp_scan/$file" --secretlintrc ".secretlintrc.json"
            FAILED=true
        fi
        cd - > /dev/null
    fi
done

# Cleanup
rm -rf "$TEMP_DIR"
if [ -d "$SHARED_REPO_DIR/secretlint/temp_scan" ]; then
    rm -rf "$SHARED_REPO_DIR/secretlint/temp_scan"
fi

if [ "$FAILED" = true ]; then
    print_error "Commit bị từ chối do phát hiện secrets"
    print_status "Vui lòng loại bỏ secrets khỏi code trước khi commit"
    exit 1
fi

print_success "Không phát hiện secrets. Commit được phép tiếp tục."
exit 0
EOF

    # Make the hook executable
    chmod +x .git/hooks/pre-commit
    
    print_success "Git pre-commit hook đã được tạo"
}

# Function to validate setup
validate_setup() {
    print_status "Kiểm tra tính toàn vẹn của setup..."
    
    local errors=0
    
    # Check shared repository
    if [ ! -d "$SHARED_REPO_DIR" ]; then
        print_error "Shared repository không tồn tại"
        errors=$((errors + 1))
    fi
    
    # Check shared resources in template
    if [ ! -d "$TEMPLATE_SHARED_DIR" ]; then
        print_error "Shared resources không được copy"
        errors=$((errors + 1))
    fi
    
    # Check custom config
    if [ ! -f "$CUSTOM_CONFIG_FILE" ]; then
        print_error "Custom secretlint config không tồn tại"
        errors=$((errors + 1))
    fi
    
    # Check secretlint in shared repo
    if [ ! -d "$SHARED_REPO_DIR/secretlint" ]; then
        print_error "Secretlint không tồn tại trong shared repository"
        errors=$((errors + 1))
    fi
    
    # Check merged secretlint config
    if [ ! -f "$SHARED_REPO_DIR/secretlint/.secretlintrc.json" ]; then
        print_error "Merged secretlint config không tồn tại"
        errors=$((errors + 1))
    fi
    
    # Check git hook
    if [ ! -f ".git/hooks/pre-commit" ]; then
        print_error "Git pre-commit hook không tồn tại"
        errors=$((errors + 1))
    fi
    
    # Check Node.js
    if ! check_node_version > /dev/null; then
        print_error "Node.js version không đạt yêu cầu"
        errors=$((errors + 1))
    fi
    
    if [ $errors -eq 0 ]; then
        print_success "Setup validation passed!"
        return 0
    else
        print_error "Setup validation failed với $errors lỗi"
        return 1
    fi
}

# Main setup function
main() {
    echo "=================================================="
    echo "    TEMPLATE REPOSITORY SETUP SCRIPT"
    echo "=================================================="
    echo ""
    
    # Check if we're in a git repository
    if [ ! -d ".git" ]; then
        print_error "Script này phải được chạy trong git repository"
        exit 1
    fi
    
    # Step 1: Check and install Node.js if needed
    if ! check_node_version; then
        if command_exists curl; then
            install_nodejs
        else
            print_error "curl không có sẵn. Vui lòng cài đặt Node.js ≥v20 manually"
            exit 1
        fi
    fi
    
    # Step 2: Setup shared repository
    setup_shared_repo
    
    # Step 3: Copy shared resources
    copy_shared_resources
    
    # Step 4: Create secretlint configuration
    create_secretlint_config
    
    # Step 5: Setup secretlint in home directory
    setup_secretlint_home
    
    # Step 6: Create git hooks
    create_git_hook
    
    # Step 7: Validate setup
    if validate_setup; then
        echo ""
        echo "=================================================="
        print_success "SETUP HOÀN THÀNH THÀNH CÔNG!"
        echo "=================================================="
        echo ""
        echo "Những gì đã được thiết lập:"
        echo "✅ Node.js ≥v20"
        echo "✅ Shared repository tại $SHARED_REPO_DIR"
        echo "✅ Shared resources tại $TEMPLATE_SHARED_DIR"
        echo "✅ Custom secretlint config tại $CUSTOM_CONFIG_FILE"
        echo "✅ Secretlint tools tại $SHARED_REPO_DIR/secretlint"
        echo "✅ Merged config tại $SHARED_REPO_DIR/secretlint/.secretlintrc.json"
        echo "✅ Git pre-commit hook"
        echo ""
        echo "Từ bây giờ, mỗi lần commit sẽ:"
        echo "• Cập nhật shared resources và secretlint tools"
        echo "• Merge secretlint configurations"
        echo "• Kiểm tra secrets trong code changes only"
        echo "• Ngăn commit nếu phát hiện secrets"
        echo ""
    else
        print_error "Setup không hoàn thành. Vui lòng kiểm tra lại các lỗi ở trên."
        exit 1
    fi
}

# Run main function
main "$@"