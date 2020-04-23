% Earth Planet
earth = Planet(6371e3, 5.97237e24, AtmosphereCOESA);

% Apollo Spacecraft
% Reference diameter/area from Moss (DSMC Simulations)
% Mass properties from "CsmLmSpacecraftOperationalDataBook-Volume3-MassProperties"
% Weight: lb -> kg, inertia moments: slug.ft^2 -> kg.m^2
apollo = Spacecraft(5856.8754, 3.9116, [8022.3748, 7149.22804, 6421.1538], 'apollo.mat');

% Max integration time
T = 3600 * 2; % 3600 * 10;

% Initial conditions
alt = 120e3;
Uinf = 10e3; % 10.73e3;
gamma = deg2rad(-6); % deg2rad(-5.9);
S0 = [alt, Uinf, gamma];
% S0 = [];

% Trajectory simulation
engine = Engine('Reltol', 1e-3, 'AbsTol', 1e-5);
[t, S, ie] = engine.integrate(T, S0, apollo, earth);

% Post
util.visualize(t, S, earth);
