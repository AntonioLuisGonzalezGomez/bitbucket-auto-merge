# Bitbucket Automation & Governance Tool (Dockerized)

A portable and fully configurable Docker-based automation and governance tool that connects to Bitbucket Server via REST API and performs automated repository operations and branch auditing.
Supported operations:

- Automatic Pull Request merge

- Source branch deletion across repositories

- Branch governance reporting & author ranking

Designed for enterprise environments where multiple repositories require controlled automation and lifecycle monitoring.

Compatible with Atlassian Bitbucket Server v7.21.7.

---

## 🚀 Features

### Core Automation

- Connects to Bitbucket Server REST API

- Supports three execution modes:

  - merge → merges eligible PRs

  - delete → deletes branches across repositories

  - report → audits all branches and generates governance reports

- Filters PRs by:

  - Project

  - Repository list

  - Author (username)

  - Source branch

  - Target branch

- Configurable minimum approvals

- Automatic source branch deletion during merge

### Governance & Reporting

- Scans all branches across repositories

- Detects:

  - Merged PR branches

  - Declined PR branches

  - Branches without commits

  - Inactive branches

  - Branches without PR

  - Active PR branches

- Calculates inactivity in days

- Generates CSV report

- Generates author ranking file

- Configurable inactivity threshold

- Persisted output via Docker volume

### Infrastructure

- Fully Dockerized (portable across environments)

- Fully configurable via environment variables

- No host dependencies required (except Docker)

- Persistent output directory

- GNU coreutils support for timestamp calculations


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
| `INACTIVE_DAYS` | Days before a branch is considered inactive (default: 30) |
| `OUTPUT_DIR`    | Local output directory for reports (default: ./output)    |

---


## 🛠 Execution Modes

The container supports two commands:
```
merge <source-branch>
delete <source-branch>
report
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
   - Cleaning feature branches across multiple repositories


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

## 📊 REPORT MODE (Branch Governance)
### What It Does

For each repository:

Retrieves all branches

- Gets last commit info

- Calculates inactivity days

- Retrieves historical PR states

- Detects commits not included in target

- Classifies each branch

| Case           | Meaning                  |
| -------------- | ------------------------ |
| 🔴 MERGED      | PR merged                |
| 🟠 PR_DECLINED | PR declined              |
| 🟠 NO_COMMITS  | No commits vs target     |
| 🟡 INACTIVE    | Inactive > INACTIVE_DAYS |
| ⚪ No problems  | Active PR open           |
| 🔵 NO_PR       | No PR exists             |

### Generated Files

When running report, two files are generated:
```
output/report.csv
output/report_ranking.csv
```

**report.csv**

Contains:

`Repository,Branch,Author,LastCommit,DaysSinceLastCommit,Reason,Case`

This provides governance visibility and accountability metrics.

### ▶ Manual Report Execution

```bash
docker run --rm --network=host \
  -e BASE_URL="https://bitbucket.company.com" \
  -e PROJECT="MYPROJECT" \
  -e USERNAME="john.doe" \
  -e PASSWORD="mySecurePassword" \
  -e TARGET_BRANCH="develop" \
  -e REPOS="repo1,repo2,repo3" \
  -e INACTIVE_DAYS=45 \
  -v $(pwd)/output:/app/output \
  bitbucket-auto-merge report
```

Reports will be stored in:

`./output/`



---


## 🧾 Using the Provided bbtool-local.sh

The helper script now supports all three modes.


### Usage
```
chmod +x bbtool-local.sh
./bbtool-local.sh merge FEATURE_X
./bbtool-local.sh delete FEATURE_X
./bbtool-local.sh report
```


### Script Parameters

`bbtool-local.sh <merge|delete|report> [source-branch]`

Examples:

```
./bbtool-local.sh merge PARALLEL_EXECUTION
./bbtool-local.sh delete PARALLEL_EXECUTION
./bbtool-local.sh report
```

The `report` mode does not require a branch parameter.

Reports will automatically be generated in:

`./output/`


---

## 🧪 Enterprise Example Use Case

Scenario:
- 25 repositories
- Feature branch: feature_parallel_execution
- All PRs target develop

Workflow:

1. Merge PRs across all repos:

```
./bbtool-local.sh merge feature_parallel_execution
```

2. Clean up branches:

```
./bbtool-local.sh delete feature_parallel_execution
```

3. Run governance audit:

```
./bbtool-local.sh report
```

This enables centralized PR merging, branch cleanup, and governance auditing across dozens of repositories.


## 🔄 CI/CD Integration Example

This container can be executed from:
- Jenkins
- GitHub Actions
- GitLab CI
- Azure DevOps
- Cron jobs

Example cron job (merge):

```
0 */2 * * * /path/to/bbtool-local.sh merge BRANCH_99564 >> merge.log 2>&1
```

Cleanup job:

```
0 3 * * * /path/to/bbtool-local.sh delete OLD_FEATURE_BRANCH >> cleanup.log 2>&1
```

Governance audit:

```
0 4 * * 1 /path/to/bbtool-local.sh report >> governance.log 2>&1
```

---

## 📦 Dependencies Inside Docker

The container installs:
- Alpine 3.18 base image

- bash

- curl

- jq

- ca-certificates

- libc6-compat

- openssl

- coreutils (GNU date support for inactivity calculations)

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

This tool evolved from a simple merge utility into a governance-oriented Bitbucket automation framework.

It now supports:

- Automated merging

- Cross-repository branch deletion

- Branch lifecycle auditing

- Author accountability ranking

- Inactivity detection

- Enterprise reporting

For production-grade enhancements (parallel execution, structured logging, JSON output, dry-run mode, Slack notifications, token-based authentication, API pagination handling, etc.), consider extending the script accordingly.