Có 2 repo trên github:
- template-repo: https://github.com/anboo44/template-repo
- shared-repo: https://github.com/anboo44/shared-repo

Template-repo có cấu trúc

```
template-repo/
│
├── .github/                          GitHub-specific configurations
│   ├── instructions/                 Project-specific instructions
│   │   ├── snowflake.instructions.md
│   │   └── unit-test.instructions.md
│   │
│   └── shared/                       Shared resources (from shared-repo)
│       ├── instructions/             Shared development guidelines
│       ├── policies/                 Shared organizational policies
│       └── prompts/                  Shared AI/automation prompts
│
├── .vscode/                          VS Code workspace settings
│   └── settings.json
├── setup.sh                          Setup script refer to shared-repo
```

Shared-repo có cấu trúc

```
shared-repo/
│
├── shared/                           Main shared content directory
│   ├── instructions/                 Shared development guidelines
│   │   ├── python.instructions.md
│   │   └── typescript.instructions.md
│   │
│   ├── policies/                     Organizational policies
│   │   ├── EnvironmentPolicy.md
│   │   └── DependencyPolicy.md
│   │
│   └── prompts/                      AI/automation prompts
│       ├── react-review.prompt.md
│       └── scala-review.prompt.md
├── secretlint/                       Secretlint config custom rule
│   ├── .default.secretlintrc.json
│   ├── merge.js
│   ├── package.json
│   └── package-lock.json
├── hooks/                            Git hooks for automation
│   └── pre-commit                    Pre-commit validation hook
```

# Yêu cầu

Cần tạo file `setup.sh` trong `template-repo`, khi tiến hành chạy file `setup.sh` sẽ thực hiện các công việc sau:
1. Sao chép thư mục `shared` từ `shared-repo` vào `.github/shared` trong `template-repo`
2. Tạo folder `.github/secretlint` trong `template-repo`
3. tạo file `.github/secretlint/custom.secretlintrc.json` trong `template-repo`. File này cho phép thêm các rule hoặc ignore rules
4. Sao chép thư mục `secretlint` từ `shared-repo` vào thư mục gốc của người dùng. Thiết lập cấu hình secretlint và cài đặt các dependencies cần thiết
5. Tạo git hooks pre-commit để thực hiện các công việc sau cho mỗi lần commit code:
+ Sao chép lại thư mục `shared` từ `shared-repo` vào `.github/shared` trong `template-repo`
+ Chạy file `merge.js` để gộp file `.default.secretlintrc.json` và `custom.secretlintrc.json` thành file `.secretlintrc.json` trong thư mục gốc của người dùng
+ Tiến hành lấy code changes và chạy secretlint để kiểm tra nếu có secrets trong code thì ngăn commit, lưu ý: chỉ kiểm tra code changes, không phải là toàn bộ file trong repo