# UI Guidelines Core

## Layout and Structure

- Prefer semantic HTML.
- Keep DOM structure stable and predictable.
- Preserve clear content hierarchy.
- Design responsive behavior intentionally.

## Components

- Build from small composable primitives.
- Keep interfaces explicit and minimal.
- Avoid prop/option explosion by splitting responsibilities.
- Keep state local until shared ownership is required.

## Styling

- Use project-consistent CSS methodology.
- Prefer design tokens/variables over magic numbers.
- Avoid deep overrides and `!important` unless unavoidable.
- Keep styling changes local to the modified surface.

## Accessibility

- Ensure labels, focus visibility, keyboard support, and sufficient contrast.
- Use ARIA only when semantics are insufficient.
- Manage focus for dynamic surfaces.

## UX, Performance, and QA

- Optimize for task completion and clear validation feedback.
- Prefer progressive enhancement and lazy-load expensive UI.
- Add tests for key rendering and interactive states.
- Keep reusable UI documentation current.
