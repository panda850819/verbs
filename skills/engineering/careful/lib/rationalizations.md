# Careful — Common Rationalizations

Anti-bypass table. Each shortcut is tied to the concrete failure it causes.

| Rationalization | Reality |
|---|---|
| "It's not really production" | If it has prod data, prod users, or shared infra (DNS, OAuth, public packages), it's prod. The blast radius defines the gate, not the label. |
| "I've done this rebase a hundred times" | Muscle memory is precisely how branches get nuked. The confirm gate is 3 seconds; recovering a force-pushed branch is 30 minutes when it's recoverable at all. |
| "Force push is fine, it's my branch" | Anyone who pulled has a divergent local copy. They will silently rebase onto the wrong head and ship phantom commits. Force push to a shared remote is never local. |
| "The migration is read-only / SELECT only" | A long SELECT on a hot table acquires locks. Read-only on a replica is OK; read-only against prod primary at peak is not. |
| "`node_modules` is exempt, so extra cleanup paths are fine too" | The exemption is path-by-path. An explicit regenerable artifact is allowed; a second non-artifact path or any glob/variable re-arms the gate for the whole command. |
| "Careful is for when I'm tired, not now" | The decision to skip the gate is itself a tiredness signal. The gate is cheap; the override is what should be expensive. |
| "I'll just ask the user one quick question to be sure" | If you can read a file or run a command to answer instead, that one quick question is a Lopopolo "continue" failure. The user's attention is more expensive than your tool calls. |
| "Asking is safer than guessing" | Sometimes. But "safer than guessing" cannot also mean "safer than checking". Check first; ask only when checking can't decide. |
