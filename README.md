# AETHER

*In greek mythology, Aether is the god of the upper sky, where the Knudsen number is so high that the continuum hypothesis breaks down. From Apollo to Artemis, it is common for space programs to be named after greek deities, and today Aerothermodynamic Estimation of Trajectories for Hypersonic Entry Research (AETHER) uses a 6-DoF solver to model the trajectories of spacecraft as they enter the atmosphere, from the upper to the lower sky.*

Welcome!

## Geting started

In order to run a case:
1. Rename the example input file `<name>_inputs.m.example` to just just `<name>_inputs.m`
2. `cd` into the root folder
3. Type `cases.<name>`
4. Analyze the results with `analysis.<name>`

New cases can be defined in the `+cases` and `+analysis` directories to have access to all the package objects.

## Code structure

Main classes:
- `Engine` is the main 6-DoF state propagator
- `Atmosphere` and all its subclasses represent atmospheric models
- `Planet` describes the planetary model
- `Spacecraft` defines the vehicle model and aerothermodynamic database interpolation

Additionally, the following packages provide extra functionality:
- `+util` includes plotting and post-processing general functions
- `+uq` includes several functions for uncertainty propagation

Note as well that currently many shared parameters are defined in the `constants` file.
