Invoke the task-planner agent to decompose the current task into an executable plan.

If $ARGUMENTS is empty, ask: "What task do you want to plan?" and wait for the user's response before proceeding.

Use the task-planner agent. The task to plan is: $ARGUMENTS

Follow the planner output format exactly:
- Goal (one sentence)
- Scope (included / excluded / must not change)
- Assumptions and risks
- Ordered, checkable steps with [?] for uncertain ones
- Verification criteria

Do not implement anything. Present the plan and wait for approval.
