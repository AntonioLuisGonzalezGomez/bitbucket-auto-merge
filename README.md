# Bitbucket Auto PR Merge (Dockerized)

A portable and fully configurable Docker-based automation tool that connects to Bitbucket Server via REST API and automatically merges Pull Requests that meet defined approval criteria.

This tool is designed for enterprise environments where multiple repositories need automated PR merging under controlled conditions.

---

## 🚀 Features

- Connects to Bitbucket Server REST API
- Filters OPEN Pull Requests
- Filters by:
    - Project
    - Repository list
    - Author (username)
    - Source branch
    - Target branch
- Automatically merges PRs with **2 or more approvals**
- Fully Dockerized (portable across environments)
- Fully configurable via environment variables
- No host dependencies required (except Docker)


---

## 🐳 Requirements

- Docker (20+ recommended)
- Linux (Alpine or any Linux distribution with Docker installed)

No additional host dependencies are required.

---

## ⚙️ Configuration

All runtime configuration is handled through environment variables.

### Required Variables

| Variable        | Description |
|----------------|-------------|
| `BASE_URL`      | Bitbucket Server base URL |
| `PROJECT`       | Bitbucket project key |
| `USERNAME`      | Bitbucket username (slug) |
| `PASSWORD`      | Password or App Password |
| `TARGET_BRANCH` | Target branch (e.g. `develop`) |
| `SOURCE_BRANCH` | Source branch to filter PRs |
| `REPOS`         | Comma-separated repository list |

Example:

```bash
BASE_URL="https://bitbucket.company.com"
PROJECT="MYPROJECT"
USERNAME="john.doe"
PASSWORD="mySecurePassword"
TARGET_BRANCH="develop"
SOURCE_BRANCH="feature_branch"
REPOS="repo1,repo2,repo3"
```



---

## 🛠 How It Works

For each repository:

1. Retrieves OPEN Pull Requests targeting `TARGET_BRANCH`
2. Filters PRs:
    - Created by `USERNAME`
    - From `SOURCE_BRANCH`
3. Counts approvals
4. If approvals ≥ 2:
    - Checks mergeability (no conflicts, no vetoes)
    - Executes merge via REST API

---

## 🔧 Build the Docker Image

From the project root:

`docker build -t bitbucket-auto-merge .`


## ▶️ Run the Container Manually

```
docker run --rm \
  -e BASE_URL="https://bitbucket.company.com" \
  -e PROJECT="MYPROJECT" \
  -e USERNAME="john.doe" \
  -e PASSWORD="mySecurePassword" \
  -e TARGET_BRANCH="develop" \
  -e SOURCE_BRANCH="feature_branch" \
  -e REPOS="repo1,repo2,repo3" \
  bitbucket-auto-merge
```

## 🧾 Using the Provided run.sh

The project includes a helper script:

```
chmod +x run.sh
./run.sh

```

Edit the configuration section inside run.sh before executing.

## 🧪 Example Use Case

Enterprise scenario:
- 25 repositories
- Multiple teams working in parallel
- All PRs from `feature_parallel_execution`
- Automatically merge to develop when 2 approvals are reached
- This tool removes the need for manual merge operations across multiple repositories.

⚠ Do NOT store plaintext passwords in version control. Consider using environment variables, Docker secrets, or Bitbucket App Passwords.



## 🔄 CI/CD Integration Example

This container can be executed from:

- Jenkins
- GitHub Actions
- GitLab CI
- Azure DevOps
- Cron jobs

Example cron execution:

`0 */2 * * * /path/to/run.sh >> merge.log 2>&1`

## 📦 Dependencies Inside Docker

The container installs:

- curl
- jq
- ca-certificates
- Alpine 3.18 base image

No external runtime dependencies required.


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

This tool is designed for internal enterprise automation scenarios where centralized PR merging across multiple repositories is required under strict approval conditions.

For production-grade enhancements (parallel execution, logging, reporting, token-based auth, dry-run mode, etc.), consider extending the script accordingly.