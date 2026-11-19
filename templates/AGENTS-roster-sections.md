<!-- Paste into the project's AGENTS.md and fill in. The roster agents read these sections
     instead of carrying project-specific values in their own files. -->

<!-- if:design -->
## Design
- Figma file: <URL>
- Figma file key: `<key>`; working page node: `<node-id>`
- Palette source: `lib/theme/app_palette.dart` (`AppPalette` ThemeExtension)
- Theme file: `lib/theme/app_theme.dart`
- Figma fields: research → ui-researcher · frames/prototype → canvas-designer · layout → ui-layout-engineer · type → type-designer · color → color-designer · a11y notes → a11y-designer · review notes → design-reviewer · Code Connect → app-bridge

<!-- endif -->
## Integrations
- Backend contract docs: `docs/integrations/<backend>.md`, ...
- Plans: `docs/integrations/<provider>-plan.md` (template: `.claude/templates/integration-plan.md`; must be APPROVED before any integration work)
- Living docs: `docs/integrations/<provider>.md`

## Layers
<!-- Optional: overrides for .claude/LAYERS.md (installed with --layers). Same table format. -->

<!-- if:testing -->
## QA
- Plan directory: `.qa/` (add to .gitignore)
- Default test budget per slice: 12
- Base branch: `main`

<!-- endif -->
## Commands
- Analyze: `flutter analyze`
- Test: `flutter test`
- Codegen: `dart run build_runner build --delete-conflicting-outputs`

## Project conventions
<!-- architecture, state management, folder layout -->

## Hard rules
<!-- things no agent may do -->

## Git
- Commits: {{COMMITS}}   (agents = subagents commit their own files, no push · user = nobody but the user commits)
- Format: Conventional Commits `<type>(<scope>): <summary>`; subagent trailer `Co-Authored-By: Claude <agent-name> <noreply@anthropic.com>`
- Branches: `<type>/<task-id>-<slug>`, created by the main agent only

## Behavior rules format
| ID | Rule | Edge cases | Status |
| --- | --- | --- | --- |
