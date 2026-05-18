---
name: linear-issue-to-pr
description: Executes Linear issue to pull request workflows. Use when the user asks to check Linear issues, create semantic branches, implement issue work, commit, push, prepare PRs, or open PRs linked to Linear.
---

# Linear Issue to Pull Request

## Required Authorization

Only perform these actions when the user explicitly asks for them:

- Create or switch branches.
- Commit changes.
- Push to a remote.
- Open or update a pull request.
- Change Linear issue status, assignee, labels, priority, or relationships.

If the user asks to "work on", "prepare a PR for", "open a PR for", or "create a branch for" a Linear issue, treat that as authorization for the named action only.

## Workflow

1. Read `AGENTS.md` and any stack-specific rules for files that will be edited.
2. Fetch the Linear issue, comments, attachments, and relations when an issue key is provided.
3. Inspect `git status`, current branch, and recent commits before creating a branch or committing.
4. Create a semantic branch when authorized:
   - `feature/<issue-key>-<short-slug>` for new behavior.
   - `fix/<issue-key>-<short-slug>` for bug fixes.
   - `chore/<issue-key-or-task-number>-<short-slug>` for maintenance or workflow/documentation.
5. Implement the smallest maintainable change that satisfies the issue.
6. Run the most relevant tests, linters, formatters, or type checks.
7. Use `cy-final-verify` before claiming completion, committing, or opening a PR when fresh verification evidence is required.
8. Commit only when authorized, using a concise semantic message that reflects the reason for the change.
9. Push only when authorized or when required for an explicitly requested PR.
10. Open the PR only when authorized.

## Pull Request Requirements

Use `gh pr create` for GitHub pull requests. Include:

- Summary of the change.
- Test plan with commands run and results.
- Linear issue link or key.
- Compozy task path when applicable.
- Review notes or follow-up risks if relevant.

Use this body shape by default:

```markdown
## Summary
- ...

## Test plan
- ...

## Linear
- ...

## Notes
- ...
```

## Linear Handling

- Prefer reading Linear issue details before implementation when an issue key is provided.
- Do not change issue status unless the user explicitly asks.
- Do not overwrite Linear descriptions or comments unless the user asks.
- When opening a PR, link the Linear issue in the PR body or use the branch name format supported by the workspace.

## Safety Checks

- Never discard unrelated working tree changes.
- Do not commit secrets or local-only configuration files.
- If unrelated changes are present, leave them alone and commit only the files relevant to the authorized task.
- If verification cannot be run, report why and include the residual risk.
