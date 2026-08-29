# spec/ — busted tests and parse fixtures

Pure-Lua tests run in CI via `busted -o utfTerminal spec` (see `.github/workflows/ci.yml`).

## Parse fixtures (`fixtures/`)

Committed sample lines for `_DW*DATA` machine channels and chat scrapers (`!port list`, `!whm spells`). Each file is named `<verb>.lines` or `<channel>_<verb>.lines`.

### Format

```text
# sender: _DWSDATA
# verb: who
d|1|who
c|10|Alice|1|99|0|0|5|0|0|0|1
z|
```

Chat fixtures use `# kind: port` or `# kind: spell` instead of `# sender:`.

Load in tests with `require('fixture_loader')`:

```lua
local fixtures = require('fixture_loader');
local fx = fixtures.load('squad_who');
fixtures.apply_machine(data, fx);
```

### Refreshing from live Driftwood

1. In game, trigger the verb (e.g. open Squad → roster refresh queues `!dws who`).
2. Capture `_DW*DATA` lines from Ashita chat or a temporary `print()` in `data.lua` `handle_machine` during dev — **do not commit real character names**; redact to placeholders (`Alice`, `Bob`, …).
3. Paste into the matching `spec/fixtures/*.lines` file; keep the `d|1|<verb>` envelope and `z|` terminator intact.
4. Run `busted spec/data_spec.lua` locally (or push and let CI run).
5. If the server bumps protocol, update `# verb` comment and fix `d|N|` version in the fixture plus `data._PROTOCOL` if needed.

Port/spell fixtures: copy a few representative lines from the human chat reply after `!port list hp` or `!whm spells`.

See also [docs/DECK.md](../docs/DECK.md) § Parse fixtures.
