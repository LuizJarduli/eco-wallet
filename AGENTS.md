# Agent Instructions

Use this file as the entry point for agent work in this repository. Before making changes, identify the stack and task type, then load the matching local rules and skills from `.agents/`.

## General Behavior

- Work in English.
- Keep solutions simple and maintainable: follow KISS, DRY, and SOLID without over-engineering.
- Prefer existing project patterns over introducing new architecture.
- Do not revert user changes unless explicitly requested.
- Never commit, push, or run destructive git commands unless the user asks for it.
- For code changes, verify with the most relevant tests, linters, formatters, or type checks available.

## Code Standards Rules

Read the relevant rule before editing files in that stack:

- Flutter and Dart: `.agents/rules/code_standars_flutter_bloc.mdc`
  - Use for `**/*.dart`.
  - Applies Effective Dart, Flutter standards, feature-first structure, and BLoC/Cubit conventions.

- React and Next.js: `.agents/rules/code_standars_react_nextjs.mdc`
  - Use for `**/*.{tsx,jsx}`.
  - Applies React, Next.js, feature-first UI structure, state, data, and testing conventions.

- Node.js REST APIs: `.agents/rules/code_standars_nodejs_rest_api.mdc`
  - Use for `**/*.{ts,js}` API/backend work.
  - Applies REST resource design, route/controller/service/repository separation, validation, errors, logging, and tests.

If multiple rules match, apply the most specific one for the files being edited. For example, use the Next.js rule for frontend `tsx` files and the Node.js REST API rule for backend API handlers or services.

## Pull Request, Branch, and Linear Workflow

- Use `.agents/skills/linear-issue-to-pr/SKILL.md` when the user asks to work from a Linear issue, create a semantic branch, prepare a PR, or open a PR linked to Linear.
- Explicit authorization is required before committing, pushing, opening a pull request, or changing Linear issue status. Requests like "work on LIN-123 and open a PR", "create a branch for this issue", or "prepare a PR" count as authorization for the named action.
- Before changing code for a Linear-backed task, inspect the issue, related comments, current git status, current branch, and relevant repository context.
- Use semantic branch names that include the issue key or task number and a short slug, such as `feature/LIN-123-carbon-wallet`, `fix/LIN-123-login-error`, or `chore/task-02-linear-pr-workflow-skill`.
- Before claiming completion, run the relevant verification. Use `cy-final-verify` when fresh evidence is required.
- For review rounds or fixing review feedback, use the dedicated Compozy review skills under `.agents/skills/`.

## Design System

- Before creating or changing UI, visual components, layout, colors, typography, spacing, or interaction states, read `DESIGN.md`.
- Use `DESIGN.md` as the source of truth for design-system development and keep new UI aligned with its tokens, component guidance, and visual direction.
- If a requested UI change conflicts with `DESIGN.md`, call out the conflict and ask for direction before introducing a new visual convention.

## Local Skills

Load a skill by reading its `SKILL.md` before using its workflow.

### GitHub and Linear

- `.agents/skills/linear-issue-to-pr/SKILL.md`
  - Use when the user asks to check Linear issues, create semantic branches, implement issue work, commit, push, prepare PRs, or open PRs linked to Linear.

### Supabase

- `.agents/skills/supabase/SKILL.md`
  - Use for any Supabase task: Database, Auth, Storage, Realtime, Edge Functions, CLI, MCP, RLS, migrations, or Supabase client integrations.
  - Verify current Supabase docs/changelog before implementation.

- `.agents/skills/supabase-postgres-best-practices/SKILL.md`
  - Use when writing, reviewing, or optimizing Postgres queries, schemas, indexes, policies, or database configuration.

### Compozy Workflow

- `.agents/skills/compozy/SKILL.md`
  - Use when explaining Compozy, its commands, configuration, artifact structure, or workflow pipeline.

- `.agents/skills/cy-create-prd/SKILL.md`
  - Use to create a PRD through interactive discovery.

- `.agents/skills/cy-create-techspec/SKILL.md`
  - Use to turn an approved PRD into a technical specification.

- `.agents/skills/cy-create-tasks/SKILL.md`
  - Use to decompose a PRD or TechSpec into executable task files.

- `.agents/skills/cy-execute-task/SKILL.md`
  - Use to execute a provided PRD task end-to-end.

- `.agents/skills/cy-workflow-memory/SKILL.md`
  - Use when a task provides workflow memory paths under `.compozy/tasks/<name>/memory/`.

- `.agents/skills/cy-review-round/SKILL.md`
  - Use to perform a structured review round for implemented PRD work.

- `.agents/skills/cy-fix-reviews/SKILL.md`
  - Use to resolve existing review issue files under `.compozy/tasks/<name>/reviews-NNN/`.

- `.agents/skills/cy-final-verify/SKILL.md`
  - Use before claiming completion, handing off work, committing, or creating a PR when fresh verification evidence is required.

## Repository Shape

- Mobile app: `apps/mobile/`
- Shared agent rules: `.agents/rules/`
- Shared agent skills: `.agents/skills/`

Prefer adding new conventions as focused `.mdc` files under `.agents/rules/` and new reusable workflows as skills under `.agents/skills/`.
