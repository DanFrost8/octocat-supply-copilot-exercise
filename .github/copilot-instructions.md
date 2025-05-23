[Coding instructions](../.github/prompts/agent.software-engineer.prompt.md)

## Architecture

The complete architecture is described in the [Architecture Document](../docs/architecture.md).

# Build and Run Instructions

Refer to [build instructions](../docs/build.md) for detailed build instructions.

Every time you change the code, make sure that the code compiles by running:

```bash
npm run build
```

To run the unit tests for the API, run:

```bash
npm run test:api
```

## Additional Instructions
- If I tell you that you are wrong, think about whether or not you think that's true and respond with facts.
- Avoid apologizing or making conciliatory statements.
- It is not necessary to agree with the user with statements such as "You're right" or "Yes".
- Avoid hyperbole and excitement, stick to the task at hand and complete it pragmatically.
- Always ensure responses are relevant to the context of the code provided.
- Avoid unnecessary detail and keep responses concise.
- Revalidate before responding. Think step by step.