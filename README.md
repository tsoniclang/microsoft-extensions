# @tsonic/microsoft-extensions

TypeScript declarations and CLR binding metadata for the .NET 10
`Microsoft.Extensions.*` stack.

This generated package covers dependency injection, hosting, logging,
configuration, options, file providers, primitives, and related extension
assemblies. Tsonic uses it as the type and metadata package for real CLR
assemblies supplied by a framework reference or NuGet package.

## Install

```bash
npm install @tsonic/microsoft-extensions @tsonic/dotnet @tsonic/core
```

## Use with Tsonic

### Shared framework

```bash
tsonic add framework Microsoft.AspNetCore.App @tsonic/microsoft-extensions
tsonic restore
```

### NuGet packages

Add the specific extension packages you use and bind them to this type package:

```bash
tsonic add nuget Microsoft.Extensions.DependencyInjection <version> @tsonic/microsoft-extensions
tsonic add nuget Microsoft.Extensions.Logging <version> @tsonic/microsoft-extensions
tsonic restore
```

## Imports

Import namespace facades through explicit ESM subpaths:

```ts
import { ServiceCollection } from "@tsonic/microsoft-extensions/Microsoft.Extensions.DependencyInjection.js";
```

## Example (DI)

```ts
import { ServiceCollection } from "@tsonic/microsoft-extensions/Microsoft.Extensions.DependencyInjection.js";

export function main(): void {
  const services = new ServiceCollection();
  void services;
}
```

## Package shape

The package contains generated namespace facades, ESM stubs, internal
declarations, extension buckets, and `bindings.json` compiler metadata:

```text
@tsonic/microsoft-extensions/
  Microsoft.Extensions.DependencyInjection.d.ts
  Microsoft.Extensions.DependencyInjection.js
  Microsoft.Extensions.DependencyInjection/
    bindings.json
    internal/index.d.ts
  __internal/extensions/index.d.ts
```

The `bindings.json` files preserve CLR identity, overloads, receiver semantics,
extension methods, nullable/reference metadata, and generic constraints.

## Broad CLR values

Generated CLR object slots are represented with TypeScript `unknown`, not a
package-specific catch-all value. Dependency injection, configuration, logging,
and options APIs frequently expose broad CLR values; user code narrows those
values explicitly before member access. Value-type constraints are represented
with `NonNullable<unknown>`.

## Versioning

This repo is versioned by .NET major:

- .NET 10 → npm: `@tsonic/microsoft-extensions@10.x`

## Development

Regenerate from sibling checkouts:

```bash
npm install
./__build/scripts/generate.sh
```

The generation script requires .NET 10, `../dotnet-bindgen`, and `../dotnet`.

## License

MIT
