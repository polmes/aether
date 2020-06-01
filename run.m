% Earth Planet
atm = AtmosphereNRLMSISE(0, 0, '21/05/2020', 12);
% atm = AtmosphereCOESA;
earth = Planet(6371e3, 5.97237e24, atm);

% Apollo Spacecraft
% Reference diameter/area from Moss (DSMC Simulations)
% Mass properties from "CsmLmSpacecraftOperationalDataBook-Volume3-MassProperties"
% Weight: lb -> kg, inertia moments: slug.ft^2 -> kg.m^2
% apollo = Spacecraft(5856.8754, 3.9116, 4.6939, [8022.3748, 7149.22804, 6421.1538], 'apollo.mat', 7.3e3);
% apollo = Spacecraft(5856.8754, 3.9116, [8000, 7000, 7000], 'fixapollo.mat');
% apollo = Spacecraft(5856.8754, 3.9116, 4.6939, [8000, 7000, 7000], 'constapollo.mat', 7.3e3);
% apollo = Spacecraft(5856.8754, 3.9116, [8000, 7000, 7000], 'constCLapollo.mat');
% apollo = Spacecraft(5856.8754, 3.9116, [8000, 7000, 7000], 'modapollo.mat');
% apollo = Spacecraft(5856.8754, 3.9116, 4.6939, [8000, 7000, 7000], 'mod2apollo.mat', 7.3e3);
% apollo = Spacecraft(5856.8754, 3.9116, 4.6939, [8022.3748, 7149.22804, 6421.1538], 'mod2apollo.mat', 7.3e3);
% apollo = Spacecraft(5860, 3.9, 4.7, [8000, 7000, 7000], 'apollomod', 7.3e3);
apollo = Spacecraft(5860, 3.9, 4.7, [8000, 7000, 7000], 'constapollo', 7.3e3);

% Max integration time
T = 2000; % 3600 * 2;

% Initial conditions
% alt = 120e3;
% Uinf = 10.73e3;
% gamma = deg2rad(-5.99); % deg2rad(-6.9);
% th = deg2rad(-40); % 0;
% [Uinf, gamma, chi, lat, lon, ph, th, ps, p, q, r]
% S0 = [alt, Uinf, gamma, 0, 0, 0, 0, th, 0];
% S0 = [alt, Uinf, gamma, pi/2, 0, 0, 0, th, pi/2];
% S0 = [alt, Uinf, gamma];
% S0 = [];
alt = 122e3; % [m] ~= 400k ft, always start at edge of atmosphere
Uinf = 11140; % [m/s] ~= 36545 ft/s
gamma = deg2rad(-7.01);
S0 = [alt, Uinf, gamma];

% Trajectory simulation
% engine = Engine('RelTol', 1e-2, 'AbsTol', 1e-4);
engine = Engine('RelTol', 1e-5, 'AbsTol', 1e-7);
tic;
[t, S, ie] = engine.integrate(T, S0, apollo, earth);
toc;

% Post
% util.post(t, S, earth, apollo);
% util.visualize(t, S, earth, apollo);
util.simple(t, S, earth, apollo);
