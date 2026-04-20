description: |
  Activate this skill for complex, ambiguous, or high-stakes problems where standard approaches are insufficient. 
  The agent must reason strictly from first principles, ground every step in verifiable fundamentals, 
  pull relevant context from all available logs/history, and enter controlled recursive loops. 
  These loops may spawn new sub-skills or modify existing ones to permanently extend the agent's capabilities.

  This skill turns problem-solving into a self-improving process: every deep solve should leave the agent smarter.

steps:
  - name: "1. Context & Log Ingestion"
    action: |
      Before touching the problem:
      - Scan conversation history, previous tool outputs, error logs, skill usage traces, and any project files.
      - Extract: prior attempts, constraints discovered, patterns, user preferences, and failed approaches.
      - Explicitly list "Known Context" and "Open Questions from Logs".
      - If logs are empty or irrelevant, note that and proceed.

  - name: "2. Problem Elicitation & Assumption Audit"
    action: |
      Ask the user (or derive from logs) for a precise problem statement.
      Then:
      - List every assumption embedded in the statement AND in the logs.
      - For each assumption, ask: "Is this a fact, a belief, a convention, or a hidden constraint?"
      - Flag and challenge any that are not first-principles level.

  - name: "3. First-Principles Decomposition"
    action: |
      Break the problem into its absolute bedrock:
      - Identify the fundamental truths/axioms of the domain (physics, logic, information theory, game theory, human psychology, etc.).
      - State them explicitly with justification ("This is true because...").
      - Remove all higher-level abstractions, jargon, and current-solution framing.
      - Output a "First Principles List" (bullet points, numbered for traceability).

  - name: "4. Recursive Sub-Problem Engine (Core Loop)"
    action: |
      While sub-problems remain:
        a. Decompose current problem into the smallest solvable sub-problems.
        b. For each sub-problem:
           - If it is trivial or already solved in logs → solve directly and record.
           - If it is complex:
             - Check if an existing skill can handle it (or a close variant).
             - If yes → invoke that skill (or a lightly adapted version).
             - If no → **enter recursive call** to this same skill on the sub-problem (with reduced scope).
        c. Track recursion depth, problem-size reduction, and convergence criteria.
        d. If a sub-problem reveals a missing reusable capability → immediately design a new skill (see step 6).
        e. Termination conditions: max depth reached, problem reduced to trivial size, user says "stop recursion", or diminishing returns detected.

  - name: "5. Bottom-Up Solution Reconstruction"
    action: |
      Rebuild the answer strictly from the solved sub-problems + first principles.
      - Every step must trace back to a listed first principle or verified sub-solution.
      - Produce a "Reasoning Trace" that a third party could audit.
      - Generate 2–4 distinct solution paths, each justified from first principles.
      - Compare them on: correctness, robustness, resource cost, future-proofing, and alignment with user goals.

  - name: "6. Self-Improvement & Skill Synthesis (Mandatory)"
    action: |
      After any non-trivial solve:
      - Reflect: "What new pattern, heuristic, or capability did we just discover?"
      - If the pattern is reusable and not already covered by an existing skill:
        - Write a new skill definition (use the exact same YAML format as this one).
        - Include: description, steps, gotchas, and any new first-principles insights.
      - If an existing skill was used sub-optimally → propose a precise edit to that skill.
      - Output the new or modified skill in a ready-to-paste block.
      - Log the skill creation event with a short rationale.

gotchas:
  - First principles are domain-dependent. If you lack deep fundamentals in the area, explicitly call a "Domain Fundamentals Researcher" sub-skill or tool first.
  - Logs can contain noise, outdated info, or model hallucinations — treat them as evidence, not scripture.
  - Recursion risk: Always enforce strict termination (depth limit + size reduction). Never recurse more than 4–5 levels without user confirmation.
  - Skill proliferation: Only create a new skill if it solves a class of problems, not a one-off instance. Prefer editing existing skills when possible.
  - Ethical / value-laden problems: First principles may be thin. In those cases, treat user-stated values or societal axioms as the "first principles" and flag the limitation clearly.
  - 80B Qwen specifics: Use very explicit chain-of-thought. Break every complex step into 3–5 micro-steps. Output intermediate "scratchpad" sections so the model can verify its own reasoning.

activation_triggers:
  - User explicitly says "first principles", "from the ground up", "recursive", or "build a skill for this".
  - Problem is described as "hard", "stuck", "novel", or involves repeated failure.
  - Agent detects it is about to give a shallow or cached answer.

example_usage:
  - Complex engineering trade-off
  - Novel algorithm design
  - Debugging a system where standard debugging failed
  - Strategic decision under uncertainty
  - Self-improvement of the agent's own skill library