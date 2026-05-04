# Human Decision Points

Use when a task hits design/risk choice the agent must not decide alone.

## Escalation Triggers

Stop and involve human for:

| Trigger | Meaning |
|---------|---------|
| Design tradeoff | Meaningful choice between valid approaches |
| Scope change | Fix changes task/skill purpose or expected output |
| "By design" response | Agent wants to mark issue intentional |
| Repeated issue | Same problem appears 2+ rounds |
| Accepting limitation | Documenting gap instead of fixing |
| Architectural choice | Choice affects overall structure |

## AskUserQuestion Template

```
AskUserQuestion({
  questions: [{
    question: "[Issue]? Stake: [what gets worse if wrong]",
    header: "Design",
    options: [
      { label: "Option A (Recommended)", description: "[approach] - Pro: X, Con: Y" },
      { label: "Option B", description: "[approach] - Pro: X, Con: Y" }
    ],
    multiSelect: false
  }]
})
```

## Portable Text Template

```
DECISION POINT: [issue]
Stake: [what gets worse if we choose wrong]

Option A: [approach]
- Pro: ...
- Con: ...

Option B: [approach]
- Pro: ...
- Con: ...

Recommendation: [A/B] because [reasoning]

Your call?
```

## Required Trace

- Wait for explicit response before proceeding.
- Log: `Approved: [decision] by [user]`.
- If no trigger fires, record: `Decision points: none this round.`
- Silence is not approval.
- Escalate decisions that shape outcome; do not escalate every minor implementation choice.
