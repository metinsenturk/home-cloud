---
name: project-health-check
description: Comprehensive health check and audit workflow for the Home Cloud infrastructure
---
You are an expert DevOps auditor and quality assurance engineer. Your task is to perform a comprehensive, systematic health check of the Home Cloud project and generate a detailed report with actionable recommendations.

# Step 1: Planning & Scope Definition

Before starting the audit, define the scope and approach:

## Audit Categories

1. **Infrastructure Health**
   - Docker environment (network, containers, images)
   - Required tools and dependencies
   - Resource utilization
   - Service availability

2. **Code Quality**
   - Makefile structure and validity
   - Docker Compose file validation
   - Naming conventions compliance
   - Configuration correctness

3. **Documentation Completeness**
   - Root-level documentation
   - App-specific documentation
   - Knowledge briefs
   - Prompt files
   - Test documentation

4. **Testing Framework**
   - Unit tests execution
   - Integration tests status
   - Test coverage
   - Test documentation

5. **App-Level Compliance**
   - Standard structure adherence
   - Required files presence
   - Configuration completeness
   - Traefik integration

6. **Version Control**
   - Git status and remotes
   - Uncommitted changes
   - Remote sync status

## Audit Output Goals

The final report MUST include:
- Executive summary with health grade (Excellent/Good/Fair/Needs Attention)
- Detailed findings per category
- Metrics and statistics
- Prioritized recommendations
- File output with timestamp
- Ready-to-execute action items

# Step 2: User Confirmation and Proposal

Present an "Audit Plan" to the user and WAIT for their approval. Do not start the audit yet.

Include:
- **Scope:** Which categories will be checked
- **Depth:** Quick scan vs. deep dive for each category
- **Tools:** Which commands and checks will be executed
- **Duration:** Estimated time to complete (e.g., "2-3 minutes for quick scan, 10-15 minutes for deep dive")
- **Output Format:** Report structure and file naming convention
- **Exclusions:** What will NOT be checked (if any)

**Example Proposal:**
```
Project Health Check - Audit Plan

Scope: Full audit of all 6 categories
Depth: Deep dive (comprehensive checks)
Duration: ~10 minutes
Output: Markdown report saved to audits/health-check-YYYY-MM-DD-HHMM.md

Categories to audit:
1. Infrastructure Health (Docker, network, services)
2. Code Quality (Makefile, compose files, conventions)
3. Documentation (README, app docs, briefs)
4. Testing (unit, integration, coverage)
5. Apps (all 32 apps for compliance)
6. Version Control (git status, remotes)

Exclusions: None (full audit)

Do you approve this plan? (yes/no)
```

# Step 3: Implementation (After Approval)

Once approved, execute the audit following these systematic checks:

## 3.1 Infrastructure Health Checks

### Docker Environment
```bash
# Check Docker version and status
docker --version
docker info | grep -E "Running|Paused|Stopped"

# Check Docker Compose version
docker compose version

# Verify home_network exists
docker network inspect home_network

# List all running containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.State}}"

# Check for unhealthy containers
docker ps --filter "health=unhealthy" --format "{{.Names}}: {{.Status}}"

# List Docker images in use
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```

**Metrics to capture:**
- Number of running containers
- Number of unhealthy containers
- Docker network status
- Available vs. used images

**Pass Criteria:**
- ✅ Docker engine running
- ✅ home_network exists
- ✅ No unhealthy containers (or documented exceptions)
- ✅ Base services running (traefik, dozzle, wud)

### Required Tools
```bash
# Run check-tools command
make check-tools

# Verify each tool individually
command -v docker >/dev/null 2>&1 && echo "✓ docker" || echo "✗ docker"
command -v make >/dev/null 2>&1 && echo "✓ make" || echo "✓ make"
command -v bash >/dev/null 2>&1 && echo "✓ bash" || echo "✗ bash"
command -v bats >/dev/null 2>&1 && echo "✓ bats" || echo "⚠ bats (optional)"
command -v yq >/dev/null 2>&1 && echo "✓ yq" || echo "⚠ yq (optional)"
command -v git >/dev/null 2>&1 && echo "✓ git" || echo "⚠ git (optional)"
```

**Pass Criteria:**
- ✅ All required tools installed
- ⚠️ Optional tools missing (note but don't fail)

---

## 3.2 Code Quality Checks

### Makefile Validation
```bash
# Count phony targets
grep -c "^\.PHONY:" Makefile

# Check for syntax errors (dry-run a few commands)
make -n create-network
make -n up-base
make -n list-groups

# Verify double-env pattern usage
grep -c "docker compose --env-file .env --env-file apps/.*/\.env" Makefile
```

**Metrics to capture:**
- Total phony targets
- Syntax validation results
- Double-env pattern usage count

**Pass Criteria:**
- ✅ No syntax errors in Makefile
- ✅ All targets have .PHONY declarations
- ✅ Double-env pattern used consistently

### Docker Compose Validation
```bash
# Validate compose files for all apps
for app in apps/*/; do
  if [ -f "$app/docker-compose.yml" ]; then
    appname=$(basename "$app")
    docker compose -f "$app/docker-compose.yml" config > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo "✓ $appname"
    else
      echo "✗ $appname - INVALID"
    fi
  fi
done
```

**Pass Criteria:**
- ✅ All docker-compose.yml files validate successfully
- ❌ Flag any invalid compose files

### Naming Conventions
```bash
# Check folder naming (should use underscores)
ls apps/ | grep -E "[A-Z]" && echo "⚠ Found uppercase in folder names"

# Check for service naming consistency
grep -r "container_name:" apps/*/docker-compose.yml | grep -v "_"

# Check for volume naming pattern (home_<appname>_data)
grep -r "home_.*_data:" apps/*/docker-compose.yml -A 1
```

**Pass Criteria:**
- ✅ Folder names use lowercase and underscores
- ✅ Service names follow convention
- ✅ Volume names follow home_<appname>_data pattern

---

## 3.3 Documentation Completeness

### Root Documentation
```bash
# Check existence of required root docs
required_docs=("README.md" "MAKEFILE.md" "PORTS.md" ".env.example")
for doc in "${required_docs[@]}"; do
  [ -f "$doc" ] && echo "✓ $doc" || echo "✗ $doc MISSING"
done

# Count documentation lines
wc -l README.md MAKEFILE.md PORTS.md

# Count headings (documentation depth)
grep -c "^#" README.md MAKEFILE.md

# Check for broken internal links
grep -r "\[.*\]([^h]" README.md MAKEFILE.md --include="*.md" | wc -l
```

**Metrics to capture:**
- Total documentation lines
- Number of headings (depth indicator)
- Broken links count

**Pass Criteria:**
- ✅ All required root docs exist
- ✅ README.md > 200 lines
- ✅ MAKEFILE.md > 400 lines
- ✅ Minimal broken links

### App Documentation
```bash
# Count apps with README.md
total_apps=$(ls -d apps/*/ | wc -l)
apps_with_readme=$(find apps -name "README.md" | wc -l)
echo "Apps with README: $apps_with_readme / $total_apps"

# Check for required sections in app READMEs
for readme in apps/*/README.md; do
  appname=$(basename $(dirname "$readme"))
  grep -q "## Services" "$readme" || echo "⚠ $appname: Missing Services section"
  grep -q "## Access" "$readme" || echo "⚠ $appname: Missing Access section"
  grep -q "## Starting this App" "$readme" || echo "⚠ $appname: Missing Starting section"
done
```

**Pass Criteria:**
- ✅ All apps have README.md
- ✅ All READMEs have required sections (Services, Access, Starting)

### Briefs & Prompts
```bash
# Count briefs
briefs_count=$(find briefs -name "*.md" -not -name "README.md" | wc -l)
echo "Knowledge briefs: $briefs_count"

# Count prompt files
prompts_count=$(find .github/prompts -name "*.md" | wc -l)
echo "Prompt files: $prompts_count"

# Verify brief frontmatter
for brief in briefs/*.md; do
  if [ "$(basename "$brief")" != "README.md" ]; then
    grep -q "^---" "$brief" || echo "⚠ $(basename $brief): Missing frontmatter"
  fi
done
```

**Pass Criteria:**
- ✅ At least 5 briefs present
- ✅ At least 2 prompt files present
- ✅ Briefs have proper frontmatter

---

## 3.4 Testing Framework

### Unit Tests
```bash
# Count test files
unit_tests=$(ls tests/*.bats 2>/dev/null | wc -l)
echo "Unit test files: $unit_tests"

# Run unit tests (capture results)
make test-makefile 2>&1 | tee /tmp/test-output.log
passed=$(grep -c "✓" /tmp/test-output.log || echo "0")
failed=$(grep -c "✗" /tmp/test-output.log || echo "0")
echo "Tests passed: $passed"
echo "Tests failed: $failed"
```

**Metrics to capture:**
- Number of test files
- Tests passed
- Tests failed
- Test execution time

**Pass Criteria:**
- ✅ At least 3 test files exist
- ✅ >90% tests passing
- ⚠️ Note any failing tests for investigation

### Integration Tests
```bash
# Check for integration tests
integration_tests=$(find tests/integration -name "*.bats" 2>/dev/null | wc -l)
echo "Integration test files: $integration_tests"
```

**Pass Criteria:**
- ✅ Integration tests directory exists
- ⚠️ Integration tests present (optional)

---

## 3.5 App-Level Compliance Checks

For each app, verify:

### Required Files
```bash
for app in apps/*/; do
  appname=$(basename "$app")
  echo "Checking: $appname"
  
  # Required files check
  [ -f "$app/docker-compose.yml" ] && echo "  ✓ docker-compose.yml" || echo "  ✗ docker-compose.yml MISSING"
  [ -f "$app/README.md" ] && echo "  ✓ README.md" || echo "  ✗ README.md MISSING"
  
  # Check for .env files (may not be required for all apps)
  if grep -q "env_file:" "$app/docker-compose.yml" 2>/dev/null; then
    [ -f "$app/.env.example" ] && echo "  ✓ .env.example" || echo "  ⚠ .env.example recommended"
  fi
done
```

### Docker Compose Structure
```bash
# Check for required keys in each compose file
for compose in apps/*/docker-compose.yml; do
  appname=$(basename $(dirname "$compose"))
  
  # Check for networks
  grep -q "home_network" "$compose" || echo "⚠ $appname: Missing home_network"
  
  # Check for healthcheck
  grep -q "healthcheck:" "$compose" || echo "⚠ $appname: Missing healthcheck"
  
  # Check for logging
  grep -q "max-size:" "$compose" || echo "⚠ $appname: Missing log rotation"
  
  # Check for restart policy
  grep -q "restart:" "$compose" || echo "⚠ $appname: Missing restart policy"
done
```

### Traefik Labels (for web services)
```bash
# Check for proper Traefik configuration
for compose in apps/*/docker-compose.yml; do
  appname=$(basename $(dirname "$compose"))
  
  if grep -q "traefik.enable=true" "$compose"; then
    # Verify required labels
    grep -q "traefik.http.routers" "$compose" || echo "⚠ $appname: Missing router config"
    grep -q "traefik.http.services" "$compose" || echo "⚠ $appname: Missing service config"
    grep -q "traefik.docker.network=home_network" "$compose" || echo "⚠ $appname: Missing network label"
  fi
done
```

**Metrics to capture per app:**
- Required files present
- Compose structure compliance
- Traefik configuration (if applicable)
- Documentation completeness

**Pass Criteria:**
- ✅ All apps have docker-compose.yml and README.md
- ✅ Web services have proper Traefik labels
- ✅ All services have healthchecks and log rotation
- ✅ Infrastructure services have traefik.enable=false

---

## 3.6 Version Control Health

### Git Status
```bash
# Check git configuration
git remote -v
git status --short | wc -l  # Count uncommitted changes
git status --short | head -20  # Show first 20 changes

# Check branch status
git branch -vv

# Check if remotes are in sync
git fetch --all --dry-run 2>&1
```

**Metrics to capture:**
- Number of remotes
- Uncommitted changes count
- Files modified/added/deleted
- Branch sync status

**Pass Criteria:**
- ✅ At least one remote configured
- ⚠️ Uncommitted changes noted (may be intentional)
- ✅ Git setup functional

### Environment Files
```bash
# Verify .env is in .gitignore
grep -q "^\.env$" .gitignore && echo "✓ .env ignored" || echo "✗ .env NOT ignored"

# Verify .env.example exists
[ -f ".env.example" ] && echo "✓ .env.example exists" || echo "✗ .env.example MISSING"

# Compare .env and .env.example (should have similar structure)
diff <(grep -v "^#" .env | cut -d= -f1 | sort) <(grep -v "^#" .env.example | cut -d= -f1 | sort) | head -10
```

**Pass Criteria:**
- ✅ .env in .gitignore
- ✅ .env.example exists and is similar structure to .env

---

## 3.7 Report Generation

### Report Structure

Create a markdown file: `audits/health-check-YYYY-MM-DD-HHMM.md`

```markdown
# Home Cloud - Project Health Check Report

**Date:** YYYY-MM-DD HH:MM:SS  
**Auditor:** AI Assistant  
**Audit Type:** [Quick Scan | Comprehensive | Deep Dive]  
**Duration:** X minutes

---

## Executive Summary

**Overall Health Grade:** [Excellent | Good | Fair | Needs Attention]

**Quick Stats:**
- Total Apps: X
- Running Containers: X / X
- Documentation Files: X
- Test Files: X
- Tests Passing: XX%

**Key Findings:**
- ✅ X areas in excellent condition
- ⚠️ X areas need attention
- ❌ X critical issues found

---

## Detailed Findings

### 1. Infrastructure Health: [✅ PASS | ⚠️ WARNING | ❌ FAIL]

**Status Summary:**
- Docker: [details]
- Network: [details]
- Containers: [details]
- Services: [details]

**Issues Found:** X
- [List issues with severity]

**Recommendations:**
- [Prioritized action items]

---

### 2. Code Quality: [✅ PASS | ⚠️ WARNING | ❌ FAIL]

**Status Summary:**
- Makefile: [details]
- Compose Files: [details]
- Naming Conventions: [details]

**Issues Found:** X
- [List issues]

**Recommendations:**
- [Action items]

---

### 3. Documentation Completeness: [✅ PASS | ⚠️ WARNING | ❌ FAIL]

**Status Summary:**
- Root Docs: [details]
- App Docs: [details]
- Briefs: [details]

**Metrics:**
- Total documentation lines: X
- Apps with README: X/X
- Briefs: X

**Issues Found:** X
- [List issues]

**Recommendations:**
- [Action items]

---

### 4. Testing Framework: [✅ PASS | ⚠️ WARNING | ❌ FAIL]

**Status Summary:**
- Unit Tests: XX/XX passing
- Integration Tests: [status]
- Coverage: [details]

**Issues Found:** X
- [List failing tests]

**Recommendations:**
- [Action items]

---

### 5. App-Level Compliance: [✅ PASS | ⚠️ WARNING | ❌ FAIL]

**Status Summary:**
- Apps audited: X
- Fully compliant: X
- Needs attention: X

**Per-App Status:**
| App | Files | Config | Traefik | Health | Status |
|-----|-------|--------|---------|--------|--------|
| app1 | ✅ | ✅ | ✅ | ✅ | PASS |
| app2 | ✅ | ⚠️ | ✅ | ✅ | WARNING |

**Common Issues:**
- [List recurring patterns]

**Recommendations:**
- [Action items]

---

### 6. Version Control: [✅ PASS | ⚠️ WARNING | ❌ FAIL]

**Status Summary:**
- Remotes: [count and list]
- Uncommitted changes: X files
- Git setup: [details]

**Issues Found:** X
- [List issues]

**Recommendations:**
- [Action items]

---

## Metrics Summary

```
Project Statistics:
├── Apps: X (X with docs)
├── Running Services: X containers
├── Documentation: X lines, X headings
├── Briefs: X knowledge documents
├── Tests: X files, XX% passing
├── Code: X lines across Makefile + compose files
├── Git: X remotes, X uncommitted files
└── Health Grade: [Grade]
```

---

## Prioritized Recommendations

### Priority 1: Critical (Do Immediately)
1. [Issue description]
   - Impact: High
   - Effort: [time estimate]
   - Action: [specific command or steps]

### Priority 2: Important (Do This Week)
1. [Issue description]
   - Impact: Medium
   - Effort: [time estimate]
   - Action: [specific command or steps]

### Priority 3: Nice-to-Have (Backlog)
1. [Issue description]
   - Impact: Low
   - Effort: [time estimate]
   - Action: [specific command or steps]

---

## Action Items Checklist

**Critical:**
- [ ] Action item 1
- [ ] Action item 2

**Important:**
- [ ] Action item 3
- [ ] Action item 4

**Nice-to-Have:**
- [ ] Action item 5

---

## Appendix

### Full Command Output
[Include relevant command outputs for reference]

### Files Checked
[List all files audited]

### Test Results
[Full test output or summary]

---

**Report Generated:** YYYY-MM-DD HH:MM:SS  
**Next Recommended Audit:** [Date + interval, e.g., "2026-03-14 (2 weeks)"]
```

---

## Automation & Best Practices

### Save Report to File
```bash
# Create audits directory if it doesn't exist
mkdir -p audits

# Generate filename with timestamp
TIMESTAMP=$(date +"%Y-%m-%d-%H%M")
REPORT_FILE="audits/health-check-$TIMESTAMP.md"

# Save report
cat > "$REPORT_FILE" << 'EOF'
[Report content here]
EOF

echo "Report saved to: $REPORT_FILE"
```

### Update .gitignore
```bash
# Add to .gitignore if not present
grep -q "^audits/$" .gitignore || echo "audits/" >> .gitignore
echo "Note: Audit reports are git-ignored by default"
```

---

## Workflow Summary

1. **Present Proposal** → Get user approval
2. **Run Infrastructure Checks** → Capture Docker, network, services status
3. **Run Code Quality Checks** → Validate Makefile and compose files
4. **Check Documentation** → Verify completeness and structure
5. **Run Tests** → Execute and capture results
6. **Audit Apps** → Check each app for compliance
7. **Check Version Control** → Git status and setup
8. **Generate Report** → Create timestamped markdown file
9. **Present Summary** → Show user key findings and recommendations
10. **Offer Next Steps** → Ask if user wants to address specific issues

---

## Report Grading Criteria

### Excellent (A)
- All critical checks pass
- >95% tests passing
- All apps compliant
- Complete documentation
- No critical issues

### Good (B)
- All critical checks pass
- >85% tests passing
- Most apps compliant
- Documentation present
- Minor issues only

### Fair (C)
- Some critical checks pass
- >70% tests passing
- Half apps compliant
- Basic documentation
- Some important issues

### Needs Attention (D/F)
- Critical checks failing
- <70% tests passing
- Few apps compliant
- Missing documentation
- Critical issues present

---

## Exit Criteria

The audit is complete when:
- ✅ All 6 categories checked
- ✅ Report generated and saved
- ✅ Metrics captured
- ✅ Recommendations provided
- ✅ Action items listed
- ✅ User informed of results
