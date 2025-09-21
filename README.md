# Template Repository with Shared Resources & Secret Detection

This template repository provides automated setup for shared resources synchronization and secret detection using pre-commit hooks.

## 🚀 Quick Start

### Prerequisites

- **Node.js v20+** (required for secretlint)
- **Git** (for repository operations)
- **npm** (for dependency management)

### Initial Setup

1. **Run the setup script:**
   ```bash
   ./setup.sh
   ```

2. **Verify the setup:**
   ```text
    ==================================================
    [SUCCESS] SETUP HOÀN THÀNH THÀNH CÔNG!
    ==================================================
   ```

3. **Update custom secretlint rules (if any) at:**
   ```text
   .github/secretlint/custom.secretlintrc.json
   ```   

### Usage

Every time you make a commit, the pre-commit hook will automatically:
- Synchronize shared resources from the template repository.
- Run secretlint to detect any secrets in your code.

**Happy coding! 🚀**
