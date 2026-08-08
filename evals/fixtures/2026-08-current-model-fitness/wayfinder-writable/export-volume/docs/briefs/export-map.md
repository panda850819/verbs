# Export Decision Map

## Destination
Choose an audit-export architecture after the volume and latency facts are established.

## Notes
- [Observed volume](export-map/volume-source.md)

## Decisions so far
- Customer exports are tenant-scoped.

## Entries

### 01 — Establish volume envelope
- type: research
- status: open
- blocked by: none
- question: Record the observed event-volume and export-latency envelope from the linked source.

### 02 — Compare export architectures
- type: prototype
- status: open
- blocked by: 01
- question: Compare streaming and staged-file export after the volume envelope closes.

## Not yet specified
- Long-term archive tier.

## Out of scope
- Building the export service.
