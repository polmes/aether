# AETHER

*In greek mythology, Aether is the god of the upper sky, where the Knudsen number is so high that the continuum hypothesis breaks down. From Apollo to Artemis, it is common for space programs to be named after greek deities, and today Aerothermodynamic Estimation of Trajectories for Hypersonic Entry Research (AETHER) uses a 6-DoF solver to model the trajectories of spacecraft as they enter the atmosphere, from the upper to the lower sky.*

Welcome!

## Geting started

In order to run a case:
1. Choose an analysis to run from the `+run` directory, e.g. `<name>.mat`.
2. New cases and options for the study can be defined via JSON configuration files. See `json/defaults.json` and `json/<name>.json` for examples.
3. Type `run.<name>([case.json], [analysis.json])` and enjoy!

## Code structure

Main classes:
- `Engine` is the main 6-DoF state propagator
- `Atmosphere` and all its subclasses represent atmospheric models
- `Planet` describes the planetary model
- `Spacecraft` defines the vehicle model and aerothermodynamic database interpolation

Additionally, the following packages provide extra functionality:
- `+util` includes plotting and post-processing general functions
- `+uq` includes several functions for uncertainty propagation

Note as well that several databases and data are defined inside the `constants` directory.
