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

## Pull Request and Review Workflow

  For creating PRs, running review rounds, or fixing review feedback, use the dedicated PR/review skill under `.agents/skills/`.
  Never commit, push, create a PR, or change Linear statuses unless the user explicitly asks. Before claiming completion, run the relevant verification and use `cy-final-verify` when fresh evidence is required.

  Then the skill can contain the real automation:

## PR and Compozy Review Workflow

  Use when the user asks to create a PR, prepare work for review, run a Compozy review round, or fix review feedback.

  1. Read `AGENTS.md`.
  2. Run fresh verification through `cy-final-verify`.
  3. Inspect `git status`, `git diff`, and recent `git log`.
  4. Commit only if explicitly requested.
  5. Push only if explicitly requested or required for PR creation.
  6. Create the PR with `gh pr create` or GitHub MCP.
  7. Include:
     - Summary
     - Test plan
     - Linear issue links
     - Compozy task path
  8. Run `/cy-review-round` for local AI review or `compozy reviews fetch` for external provider feedback.
  9. Use `cy-fix-reviews` to resolve review issue files.
  10. Re-run verification before reporting completion.

## Design System

- Before creating or changing UI, visual components, layout, colors, typography, spacing, or interaction states, read `DESIGN.md`.
- Use `DESIGN.md` as the source of truth for design-system development and keep new UI aligned with its tokens, component guidance, and visual direction.
- If a requested UI change conflicts with `DESIGN.md`, call out the conflict and ask for direction before introducing a new visual convention.

## Local Skills

Load a skill by reading its `SKILL.md` before using its workflow.

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
