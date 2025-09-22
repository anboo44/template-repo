# Template Repository with Shared Resources & Secret Detection

This template repository provides automated setup for shared resources synchronization and secret detection using pre-commit hooks.

## 🚀 Quick Start

### Prerequisites

- **Node.js v20+** (required for secretlint)
- **Git** (for repository operations)
- **npm** (for dependency management)

### Initial Setup on your repository

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
   .vscode/custom.secretlintrc.json
   ```   

### Usage

Everytime you make a commit, the pre-commit hook will automatically:
- Synchronize shared resources from the template repository.
- Run secretlint to detect any secrets in your code.

![Prevent commit example](prevent-commit.png)

**Happy coding! 🚀**
