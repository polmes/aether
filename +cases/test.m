% Load inputs
eval(['cases.' mfilename '_inputs']);

% Load global constants
constants;

% Initialize objects
sc = Spacecraft(apollo.m, apollo.L, apollo.R, apollo.I, file, apollo.deploy); % Apollo spacecraft
at = AtmosphereNRLMSISE(atm.lat, atm.lon, atm.date, atm.hrs); % standard NRLMSISE
pl = Planet(earth.R, earth.M, at); % Earth properties

% Solver setup
S0 = [alt, Uinf, gamma]; % initial state vector
engine = Engine('RelTol', 1e-3, 'AbsTol', 1e-5);

% Trajectory simulation
tic;
[t, S, ie] = engine.integrate(T, S0, sc, pl);
toc;

% Post
util.simple(t, S, sc, pl);
