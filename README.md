# Bitbucket Automation Tool (Dockerized)

A portable and fully configurable Docker-based automation tool that connects to Bitbucket Server via REST API and performs automated repository operations.

Supported operations:

- Automatic Pull Request merge

- Source branch deletion across repositories

Designed for enterprise environments where multiple repositories require controlled automation.

Compatible with Atlassian Bitbucket Server v7.21.7.

---

## 🚀 Features

- Connects to Bitbucket Server REST API
- Supports two execution modes:
  - merge → merges eligible PRs
  - delete → deletes branches across repositories
- Filters PRs by:
  - Project
  - Repository list
  - Author (username)
  - Source branch
  - Target branch
- Configurable minimum approvals
- Automatic source branch deletion during merge
- Fully Dockerized (portable across environments)
- Fully configurable via environment variables
- No host dependencies required (except Docker)


---

## 🐳 Requirements

- Docker 20+
- Linux host (Alpine or any distribution with Docker installed)
- Network access to Bitbucket Server

No additional host dependencies are required.

---

## ⚙️ Configuration

Runtime configuration is handled via environment variables.

### Required Variables

| Variable        | Description |
|----------------|-------------|
| `BASE_URL`      | Bitbucket Server base URL |
| `PROJECT`       | Bitbucket project key |
| `USERNAME`      | Bitbucket username (slug) |
| `PASSWORD`      | Password or App Password |
| `TARGET_BRANCH` | Target branch (e.g. `develop`) |
| `REPOS`         | Comma-separated repository list |


### Optional Variables

| Variable        | Description |
|----------------|-------------|
| `MIN_APPROVALS` | Minimum number of approvals required to merge a PR (default: 2) |

---


## 🛠 Execution Modes

The container supports two commands:
```
merge <source-branch>
delete <source-branch>
```

## 🔀 MERGE MODE
### What It Does

For each repository:
1. Retrieves OPEN PRs targeting TARGET_BRANCH
2. Filters PRs:
   - Created by USERNAME
   - From <source-branch>
3. Counts approvals
4. If approvals ≥ MIN_APPROVALS:
   - Checks mergeability (no conflicts, no vetoes)
   - Executes merge
   - Requests automatic source branch deletion


---

## ▶️ Manual Merge Execution

```bash
docker run --rm --network=host \
  -e BASE_URL="https://bitbucket.company.com" \
  -e PROJECT="MYPROJECT" \
  -e USERNAME="john.doe" \
  -e PASSWORD="mySecurePassword" \
  -e TARGET_BRANCH="develop" \
  -e REPOS="repo1,repo2,repo3" \
  -e MIN_APPROVALS=2 \
  bitbucket-auto-merge merge feature_branch
```

## 🗑 DELETE MODE
### What It Does

For each repository:
1. Checks if <source-branch> exists
2. If it exists:
   - Deletes the branch via REST API
3. If it does not exist:
    - Skips safely
This mode is useful when:
   - PRs were already merged
   - You want to clean up feature branches across multiple repositories


## ▶️ Manual Delete Execution
```bash
docker run --rm --network=host \
-e BASE_URL="https://bitbucket.company.com" \
-e PROJECT="MYPROJECT" \
-e USERNAME="john.doe" \
-e PASSWORD="mySecurePassword" \
-e TARGET_BRANCH="develop" \
-e REPOS="repo1,repo2,repo3" \
bitbucket-auto-merge delete feature_branch
```

---

## 🧾 Using the Provided bbtool-local.sh

The helper script now supports both modes.

### Usage
```
chmod +x bbtool-local.sh
./bbtool-local.sh merge FEATURE_X
```

or

```
./bbtool-local.sh delete FEATURE_X
```
### Script Parameters
bbtool-local.sh <merge|delete> <source-branch>

Example:
```
./bbtool-local.sh merge PARALLEL_EXECUTION
./bbtool-local.sh delete PARALLEL_EXECUTION
```

---

## 🧪 Enterprise Example Use Case

Scenario:
- 25 repositories
- Feature branch: feature_parallel_execution
- All PRs target develop

Workflow:

1. Run:
```
./bbtool-local.sh merge feature_parallel_execution
```
2. After verification:
```
./bbtool-local.sh delete feature_parallel_execution
```
This removes the need for manual PR merges and manual branch cleanup across dozens of repositories.


## 🔄 CI/CD Integration Example

This container can be executed from:
- Jenkins
- GitHub Actions
- GitLab CI
- Azure DevOps
- Cron jobs

Example cron job:
```
0 */2 * * * /path/to/bbtool-local.sh merge BRANCH_99564 >> merge.log 2>&1
```
Or for cleanup:
```
0 3 * * * /path/to/bbtool-local.sh delete OLD_FEATURE_BRANCH >> cleanup.log 2>&1
```

---

## 📦 Dependencies Inside Docker

The container installs:
- bash
- curl
- jq
- ca-certificates
- libc6-compat
- openssl
- Alpine 3.18 base image

No external runtime dependencies required.

---

## 🔐 Security Notice

⚠ Do NOT store plaintext passwords in version control.

Recommended alternatives:
- Environment variables injected by CI/CD
- Docker secrets
- Bitbucket App Passwords
- Vault integrations

---


## 📜 License

MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.

## 🤝 Contributing

Pull requests are welcome.

For major changes, please open an issue first to discuss what you would like to change.

## 👨‍💻 Author

Antonio Luis González Gómez


## ⭐ Final Notes

This tool is designed for internal enterprise automation scenarios where centralized PR merging and branch lifecycle management across multiple repositories is required under strict approval conditions.

For production-grade enhancements (parallel execution, structured logging, reporting, token-based authentication, dry-run mode, Slack notifications, etc.), consider extending the script accordingly.