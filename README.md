## Approve and Bridge

> [!CAUTION]
> This is a proof of concept, not a production-ready contract!
> It needs to be properly reviewed and audited before actually using it.

A helper contract to support the swap-and-bridge feature through CoW Protocol.

Each supported bridge has its own dedicated helper contract.

The helper contract is intended to be delegatecalled from a CoW Shed contract instance.
See the forked tests in `test/e2e/` for usage details.

## Development

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Format

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```

### Deploy

```shell
forge script script/Deploy.s.sol:DeployScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```
