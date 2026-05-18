# Data

`tesla.csv` is the repository-local Tesla EV telemetry table used by the graph-recovery notebook.

The thesis task selects six normalized telemetry features from this file:

- `electricenergyremaining`
- `electricremaining`
- `speed_kmh`
- `acceleration_kmh2`
- `mileage`
- `distance_m`

The source fields `timestamp` and `vehiclespeed` are not part of the evaluated graph-recovery task.
