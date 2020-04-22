% Input
earth = Planet(6371e3, 5.97237e24, AtmosphereStd76);
apollo = Spacecraft(1000, 1, 2/3*100*1^2 * ones(1, 3), 'apollo.mat');
T = 3600 * 10; % max integration time

% Initial conditions
alt = 120e3;
Uinf = 12e3; % 10.73e3;
gamma = deg2rad(-5); % deg2rad(-5.9);
S0 = [alt, Uinf, gamma];
% S0 = [];

% Trajectory simulation
engine = Engine; % keep defaults
[t, S, ie] = engine.integrate(T, S0, apollo, earth);

% Post
util.visualize(S, earth);
