# Machine channels (0x0017 spike)

DriftwoodXI addons exchange structured data over Ashita **outgoing chat** packets (`0x0017`). The sender field (bytes `0x09–0x17`) identifies the addon; the message body (from `0x18`) is a pipe-delimited envelope.

Pad Hub **observes** these packets and must not block official `dw*` addons from owning their senders.

## Packet layout

| Offset | Field |
|--------|--------|
| `0x09–0x17` | Sender name (NUL-padded), e.g. `_DWSDATA` |
| `0x18+` | Message body (UTF-8 text, pipe fields) |

`data.lua` extracts sender and body in `attach()` and routes through `handle_machine(sender, message)`.

## Envelope grammar (protocol v1)

All channels share the same framing used by squad, bags, jobs, and rules:

| Kind | Form | Meaning |
|------|------|---------|
| `d` | `d\|1\|<verb>` | Start envelope for `<verb>` |
| `m` / `e` | `m\|<text>` / `e\|<text>` | Human status or error line |
| `z` | `z` | End envelope |
| *(data)* | `<kind>\|…` | Verb-specific rows between `d` and `z` |

### Worked example — squad `who` (fixture: `spec/fixtures/squad_who.lines`)

```
d|1|who
c|10|Alice|6|75|0|0|0|0|0|1
c|11|Bob|15|60|0|0|0|0|0|2
z
```

### Worked example — bags `find` (fixture: `spec/fixtures/bags_find.lines`)

```
d|1|find
f|10|0|1:4096:12:0
z
```

## Typed command → machine prefix map

| Hub category | Typed command | Machine prefix | Sender (expected) | Parse status |
|--------------|---------------|----------------|-------------------|--------------|
| Squad | `!squad`, `!dws` | `!dws` | `_DWSDATA` | **Shipped** |
| Items / bags | `!dwq`, `!squad find` | `!dwq` | `_DWDATA` | **Shipped** |
| Jobs | `!jobs`, `!dwj` | `!dwj` | `_DWJDATA` | **Shipped** |
| Rules | `!squad rules`, `!dwg` | `!dwg` | `_DWGDATA` | **Shipped** |
| Storage | `!warehouse`, `!dwu` | `!dwu` | `_DWUDATA` | Stub observe |
| Market | `!market`, `!dwa` | `!dwa` | `_DWADATA` | Stub observe |
| Merc | `!merc`, `!dwm` | `!dwm` | `_DWMDATA` | Stub observe |
| Quests | `/tracker`, `!dwt` | `!dwt` | `_DWTDATA` | Stub observe |
| Drift | `!drift`, `!dwn` / `!dwo` | `!dwn` / `!dwo` | `_DWNDATA` / `_DWODATA` | Stub observe (TBD) |
| Fish | `!fish`, `!fish next`, … | `!dwf` | `_DWFDATA` | Fish UI shipped (#47); machine parse stub |
| Raid | `!raid` | *(chat)* / `!dwr`? | *(TBD)* | Chat-only today |
| Arena | `!arena` | *(chat)* | *(none)* | Chat-only today |
| Scan | `!scan`, `!scan 0 N` | *(chat)* / `!dwx`? | `_DWXDATA` | Scan UI shipped (#46); chat-only |
| Engage | `!trustengage`, `/dwengage on\|off` | `!dwe`? | `_DWEDATA` | Engage UI shipped (#45); machine parse stub |
| Report | `!dwreport` | `!dwr` | `_DWRDATA` | Not in hub UI |

**Note:** `_DWRDATA` is used by **dwreport** in current Lumoria installs. Raid may remain chat-only until sender ownership is confirmed.

## Registry in `data.lua`

`SENDERS` maps sender string → logical channel. Shipped parsers: `squad`, `bags`, `jobs`, `rules`. All other registered channels use `handle_stub_envelope` (buffers rows, surfaces `m`/`e` status) until child issues add typed parsers.

## Capture procedure (live samples)

1. Install the target official addon (e.g. `dwwarehouse`) beside Pad Hub.
2. Reload both: `/addon reload dwwarehouse` then `/addon reload dwhub`.
3. Trigger a read-only verb (e.g. `!warehouse`, `!dwt sync`).
4. Log packets with a temporary hook or Ashita packet log filtered to `0x0017`.
5. Redact character names and IDs; append lines to `spec/fixtures/<channel>_<verb>.lines` with a `# sender:` header (see `spec/README.md`).
6. Add a `data_spec.lua` example once the fixture is stable.

### Placeholder samples (unverified — replace after capture)

**Warehouse summary (`!warehouse` / `!dwu`):**

```
d|1|summary
m|Account warehouse: 12 slots used.
z
```

**Tracker sync (`!dwt sync`):**

```
d|1|sync
m|Journal refreshed.
z
```

**Merc board (`!merc board` / `!dwm`):**

```
d|1|board
m|3 mercenaries available.
z
```

## References

- Pad Hub parsers: `addons/dwhub/data.lua`
- Command builders: `addons/dwhub/cmds.lua`
- MENU-IA categories: `docs/MENU-IA.md`
- Epic tracker: [#44](https://github.com/JRustyHaner/driftwoodxi-pad-hub/issues/44)
