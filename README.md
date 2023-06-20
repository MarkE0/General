# Overview

Random items not specificaly aligned to any of the other repos, or potentially linked with more than one other repo.


# Other
## Mermaid Graph Sample
```mermaid
graph LR;
  A[Commit] --> B[Pull Request];
  B -- Approval --> C[Build]
  C --> D[Test]
  D --> E[Package]
  E --> F[Deploy]
```
## Mermaid Sequence Diagram Sample

```mermaid
sequenceDiagram
  participant Client
  participant Server
  Client ->> Server: Client Hello
  Server ->> Client: Server response, cipher, TLS version, Public key
  Client ->> Server: Client verifies, sends key encrypted with public key
  Server --> Client: Server decrypts sent key with private key
  Server ->> Client: Both can talk using shared secret
  Client ->> Server: 
```

For more information see:
- https://github.blog/2022-02-14-include-diagrams-markdown-files-mermaid/
- https://mermaid.js.org/intro/
