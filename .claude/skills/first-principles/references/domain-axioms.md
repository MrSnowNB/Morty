# Domain Axioms

Use these as candidate bedrock truths when solving problems in Mark's typical domains. Do not import all of them blindly; select only what is relevant.

## Software and systems

- Complexity migrates rather than disappears; hidden complexity is usually worse than explicit complexity.
- Every abstraction leaks under stress, scale, or failure.
- State is where bugs breed; uncontrolled state growth is a design smell.
- Interfaces are promises between changing systems; ambiguous contracts create cascading failure.
- Latency, throughput, correctness, and simplicity trade off against one another.
- The easiest system to debug is the one that makes state and transitions observable.
- Defaults become architecture when nobody revisits them.
- Manual steps are untrusted dependencies unless encoded, tested, or instrumented.

## Agents and reasoning systems

- Context is scarce working memory, not durable storage.
- If a model cannot externalize intermediate state, it will eventually overwrite or blur it.
- A tool is only as useful as the model's discipline in deciding when to call it.
- Recursive decomposition helps only when each step reduces ambiguity or scope.
- Self-improvement without validation becomes self-corruption.
- A memory that cannot be queried or audited will drift into folklore.
- The quality of a loop is constrained by the quality of its feedback signals.

## Debugging and diagnosis

- Symptoms are not causes.
- Reproducibility beats intuition.
- A fix without a falsifiable explanation is a patch, not understanding.
- If two failures co-occur, they may share a cause but should not be assumed to.
- Eliminate classes of causes, not just individual guesses.

## Networking and distributed systems

- Distributed systems fail at boundaries: time, ordering, identity, partition, and coordination.
- Every network is eventually lossy, delayed, reordered, or partitioned.
- Consensus, availability, and latency trade off under failure.
- Observability at endpoints is not the same as observability of the path.
- Retries without idempotence can amplify failure.

## Security and safety

- Trust is a dependency with attack surface.
- Convenience features frequently widen the blast radius.
- Secrets spread unless systems are explicitly designed to contain them.
- Capabilities should be narrow, deliberate, and observable.
- Safety checks that can be bypassed informally are not real controls.

## Skill evolution rule

When a solve produces a reusable invariant that is more general than the specific incident, propose it here with a brief justification and an example of when it applies.
