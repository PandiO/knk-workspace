# Git Commit Conventions

## Overview
This document defines standardized commit message formats for all Knights & Kings repositories to ensure consistency, clarity, and traceability across the entire project. All AI-generated commit messages must adhere to these conventions.

**Repositories covered:**
- knk-web-api-v2 (.NET Web API)
- knk-web-app (React/TypeScript frontend)
- knk-plugin-v2 (Minecraft plugin)
- Documentation repositories

---

## Commit Subject Line Format

### General Structure
```
<type>(<scope>): <subject>
```

### Type
Required. Specifies the category of change:

| Type | Used For | Example |
|------|----------|---------|
| `feat` | New feature or capability | `feat(api): add user authentication endpoint` |
| `fix` | Bug fix | `fix(plugin): resolve memory leak in cache invalidation` |
| `docs` | Documentation only (no code changes) | `docs: update installation guide` |
| `refactor` | Code restructuring without functional change | `refactor(web): simplify form validation logic` |
| `perf` | Performance improvement | `perf(cache): optimize query execution` |
| `test` | Test additions or updates | `test(api): add integration tests for user service` |
| `ci` | CI/CD pipeline changes | `ci: add GitHub Actions workflow for plugin build` |
| `style` | Code style, formatting (no logic changes) | `style: format code to match ESLint rules` |
| `chore` | Dependencies, tooling, config | `chore: upgrade Gradle to 8.11` |

### Scope
Optional but recommended. Specifies the module or component affected:

**Backend (.NET):**
- `api`, `dto`, `service`, `repository`, `config`, `auth`, `validation`

**Frontend (React):**
- `ui`, `form`, `list`, `detail`, `modal`, `hook`, `service`, `store`

**Plugin (Java/Kotlin):**
- `core`, `cache`, `listener`, `command`, `config`, `mapper`, `api-client`

**Documentation:**
- Omit scope or use `docs` if no specific scope applies

### Subject
- **Lowercase** first letter
- **Imperative mood**: "add" not "adds", "fix" not "fixed"
- **No period** at the end
- **Maximum 50 characters** (strict limit)
- **Specific**: describe what changed, not why

### Subject Examples

✅ **Good:**
- `feat(cache): add stale-ok fallback strategy`
- `fix(listener): prevent race condition in player login`
- `docs: update data-access-unification phase 2 status`
- `refactor(form): extract validation logic to hook`

❌ **Bad:**
- `feat: stuff` (too vague)
- `Fixed the bug in the cache` (past tense, too long)
- `Update documentation.` (period, no type)
- `feat(core): Add FetchPolicy enum and related types` (capitalized)

---

## Commit Description Format

### Structure
```
<blank line>
<body>
<blank line>
<footer (optional)>
```

### Body
- **Wrap at 72 characters** for readability in terminals and GitHub
- **Explain what changed and why**, not how (code is self-documenting)
- **Use present tense**: "add", "change", "remove"
- **1+ paragraphs**, each separated by blank lines
- **Bullet points** for lists of related changes (use `-` or `*`)

### Footer (Optional)
Used for:
- **Breaking changes**: Start with `BREAKING CHANGE:` followed by explanation
- **Related issues**: `Fixes #123`, `Related to #456`
- **References**: `See docs/data-access-unification/` or `Implementation: docs/specs/api/`

### Description Examples

#### Example 1: Feature Implementation (Plugin)

**Subject:**
```
feat(core): implement unified data access foundations (Phase 2)
```

**Description:**
```
Implement Phase 2 of the unified data access layer to provide consistent,
cache-aware data retrieval across the plugin.

This foundation enables domain gateways to orchestrate cache/API interactions
with minimal boilerplate while supporting multiple fetch strategies and
resilient error handling.

Components added:
- FetchPolicy enum: 5 fetch strategies (CACHE_ONLY, CACHE_FIRST, API_ONLY,
  API_THEN_CACHE_REFRESH, STALE_OK)
- FetchStatus/DataSource enums: typed status and source tracking
- FetchResult<T>: type-safe result wrapper with functional operations
  (map, ifSuccess, ifError, orElse, orElseThrow)
- DataAccessExecutor<K,V>: reusable helper implementing complete policy flow
  with both sync (fetchBlocking) and async (fetchAsync) APIs
- RetryPolicy: configurable exponential backoff for transient network failures
  (max 3 attempts, 100ms initial delay, 2.0 multiplier, 5s max)

Package: net.knightsandkings.knk.core.dataaccess
Build: Verified successful compilation
Next: Phase 3 - Users Gateway pilot implementation

Related: data-access-unification spec (docs/data-access-unification/)
```

#### Example 2: Bug Fix (Backend)

**Subject:**
```
fix(service): correct null reference in user creation flow
```

**Description:**
```
A null reference exception was thrown when creating a new user if no
default preferences were provided. The UserService now safely handles
missing optional fields by initializing with sensible defaults.

Root cause: UserDetail.preferences field was not checked for null before
being passed to the database layer.

Changes:
- Add null check in UserService.createUser()
- Initialize default Preferences object when null
- Add unit test to verify behavior with missing preferences

Fixes #892
```

#### Example 3: Documentation (Docs Repo)

**Subject:**
```
docs: mark Phase 2 complete for data-access-unification
```

**Description:**
```
Phase 2 (Foundations) of the unified data access implementation is complete.
All core infrastructure components have been implemented and verified.

Completed deliverables:
- FetchPolicy, FetchStatus, DataSource enums
- FetchResult<T> type-safe result wrapper
- DataAccessExecutor helper with sync/async APIs
- RetryPolicy with exponential backoff
- Comprehensive package documentation

Status: Ready for Phase 3 (Users Gateway pilot implementation)
Build: knk-core module compiles successfully
Package: net.knightsandkings.knk.core.dataaccess
```

#### Example 4: Refactor (Frontend)

**Subject:**
```
refactor(form): extract reusable validation error component
```

**Description:**
```
Extract the validation error display logic into a standalone
ValidationErrorMessage component to reduce duplication across form pages.
Previously, error rendering was copy-pasted in CreateForm, EditForm, and
DetailForm.

Benefits:
- Single source of truth for error styling and messaging
- Easier to update error UX globally
- Improves component reusability

Changes:
- Create new ValidationErrorMessage component with props for error type
  and message
- Update CreateForm, EditForm, DetailForm to use new component
- Remove 40+ lines of duplicated JSX
- Add Storybook story for component
- Update tests to verify new component behavior

Related: #445 (form UX improvements epic)
```

---

## Type-Specific Guidelines

### Backend (.NET / knk-web-api-v2)

**Scope Priority:**
- `service`, `repository`, `dto`, `controller`, `validation`, `config`

**Subject Examples:**
- `feat(service): implement bulk user fetch with caching`
- `fix(validation): correct email regex pattern`
- `test(repository): add integration tests for town queries`

**Description Tips:**
- Mention affected DTOs or endpoints
- Reference database changes if applicable
- Include any breaking API changes

---

### Frontend (React/TypeScript / knk-web-app)

**Scope Priority:**
- `form`, `ui`, `hook`, `service`, `store`, `modal`, `list`, `detail`

**Subject Examples:**
- `feat(form): add real-time validation feedback`
- `fix(hook): prevent memory leak in useEffect cleanup`
- `refactor(ui): consolidate button styles into design system`

**Description Tips:**
- Mention component names or page affected
- Note any breaking UI changes
- Include accessibility improvements if relevant

---

### Plugin (Java/Kotlin / knk-plugin-v2)

**Scope Priority:**
- `core`, `cache`, `listener`, `command`, `service`, `mapper`, `api-client`

**Subject Examples:**
- `feat(listener): add async player location tracking`
- `fix(cache): resolve TTL expiration timing issue`
- `perf(api-client): batch API requests to reduce network calls`

**Description Tips:**
- Mention related Paper/Bukkit events if applicable
- Include performance metrics if relevant
- Note any configuration changes needed

---

### Documentation (docs/)

**Scope:**
- Usually omitted (use `docs` as type)
- Alternatively use the document topic: `docs(data-access)`, `docs(towns)`

**Subject Examples:**
- `docs: update installation guide for Phase 2 release`
- `docs(towns): add flow diagram for split-towns feature`
- `docs(api): document new user authentication endpoints`

**Description Tips:**
- Be brief—describe what sections changed
- Link to related implementation commits if applicable
- Note any related PRs/issues

---

## Using This Document with AI

### Prompting AI for Commits

**Method 1: Reference this document**
```
Generate a git commit message for [feature/fix].
Adhere to the format in docs/GIT_COMMIT_CONVENTIONS.md.
```

**Method 2: Inline specification**
```
Generate a commit message in the format:
- Subject: <type>(<scope>): <message> (max 50 chars, lowercase, imperative)
- Description: Explain what and why (wrap at 72 chars)
Include details about [specific change].
```

**Method 3: Example-based**
```
Generate a commit message similar to this example:
  Subject: feat(core): implement unified data access foundations (Phase 2)
  Description: [Comprehensive description explaining deliverables, status, etc.]
```

### Automation with AI

**1. Integrate Into Workflow**
- Keep a shortcut or alias that references this document
- Example: `git-commit-template docs/GIT_COMMIT_CONVENTIONS.md`

**2. Include in Prompts**
Every commit generation prompt should include:
```
Follow the format in docs/GIT_COMMIT_CONVENTIONS.md:
- Type: <type> from the defined list
- Scope: from the repo's scope priority list
- Subject: Imperative mood, lowercase, max 50 chars
- Description: Explain what and why, wrap at 72 chars
```

**3. Validation Checklist**
Before executing `git commit`, verify:
- [ ] Subject starts with type and scope: `<type>(<scope>): `
- [ ] Subject is under 50 characters
- [ ] Subject is lowercase and imperative mood
- [ ] Subject has no period at the end
- [ ] Description exists (if commit is non-trivial)
- [ ] Description paragraphs wrap at ~72 characters
- [ ] Description explains "what" and "why", not "how"
- [ ] Footer includes issue references if applicable

---

## Tools & Enforcement (Optional)

### Husky + commitlint (Recommended)
If you want to enforce these conventions automatically:

```bash
# Install dependencies
npm install husky @commitlint/config-conventional @commitlint/cli --save-dev

# Setup commit hook
npx husky install
npx husky add .husky/commit-msg 'npx --no -- commitlint --edit "$1"'

# Create commitlint.config.js
echo "module.exports = { extends: ['@commitlint/config-conventional'] };" > commitlint.config.js
```

This will reject commits that don't follow Conventional Commits format.

---

## FAQ

**Q: Can I use multiple scopes?**
A: No. Stick to one scope. If multiple components are affected, either choose the primary one or reconsider splitting the commit.

**Q: What if my commit is a work-in-progress?**
A: Don't commit to main branches. Use feature branches and only clean up commits before merging.

**Q: How long should the description be?**
A: At minimum 1-2 sentences explaining the "why". Longer is fine if it adds clarity. Aim for 50-200 words typically.

**Q: Do I need a description for trivial fixes?**
A: A 1-2 sentence description is always helpful, even for trivial changes. It gives future maintainers context.

**Q: What about squash merges?**
A: Ensure the squashed commit message still follows this format. The merge commit is the "real" commit history.

---

## Examples by Repository

### knk-web-api-v2 Examples
```
feat(dto): add UserDetailDto with embedded preferences
fix(controller): validate town owner permissions before update
test(service): add regression test for concurrent user creation
refactor(repository): extract common query predicates
perf(service): cache town hierarchy to reduce N+1 queries
```

### knk-web-app Examples
```
feat(form): implement multi-step town creation wizard
fix(hook): correct dependency array in useUserFetch
refactor(ui): extract town card into reusable component
test(form): add validation tests for email field
style(form): align button spacing with design system
```

### knk-plugin-v2 Examples
```
feat(core): implement unified data access foundations (Phase 2)
fix(listener): prevent player event race condition on login
perf(cache): add write-through optimization for bulk operations
refactor(mapper): consolidate entity-to-DTO mapping
test(executor): add integration tests for FetchPolicy strategies
```

### Documentation Examples
```
docs: add Phase 2 completion summary for data-access-unification
docs(towns): update requirements for hybrid create/edit flow
docs(api): document new town bulk-fetch endpoint
docs: update CODEMAP with new module structure
```

---

## References

- [Conventional Commits](https://www.conventionalcommits.org/) (inspiration)
- Knights & Kings Architecture: [docs/CODEMAP.md](CODEMAP.md)
- Project-specific conventions: [.github/](../.github/)

---

## Version History

| Date | Author | Change |
|------|--------|--------|
| 2026-01-25 | AI Template | Initial version - establish commit conventions |

---

**Last Updated:** January 25, 2026  
**Status:** Active  
**Maintainer:** Development Team
