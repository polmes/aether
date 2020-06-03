% INPUT

name = 'tol';

tol = logspace(-1, -10, 10); % RelTol's (AbsTol's are x1e-2)

% file = 'constapollo';
file = 'apollomod';

%% PRE

% Constants
sc = Spacecraft(5860, 3.9, 4.7, [8000, 7000, 7000], file, 7.3e3); % Apollo spacecraft
at = AtmosphereNRLMSISE(0, 0, '24/07/1969', 12); % standard NRLMSISE
pl = Planet(6371e3, 5.97237e24, at); % Earth properties

% Initial conditions (from Apollo 4, ignoring lat/lon)
alt = 122e3; % [m] ~ 400k ft, always start at edge of atmosphere
Uinf = 11140; % [m/s] ~ 36545 ft/s
gamma = deg2rad(-7.01);
S0 = [alt, Uinf, gamma];

% Constant parameters
T = 2000; % max integration time
NT = numel(tol);

%% MAIN

% Init
t = cell(1, NT);
S = cell(1, NT);
ie = zeros(1, NT);
for i = 1:NT
	engine = Engine('RelTol', tol(i), 'AbsTol', tol(i) * 1e-2, 'ShowWarnings', false);

	tic;
	[t{i}, S{i}, ie(i)] = engine.integrate(T, S0, sc, pl);
	toc;
end

%% POST

% Save data
filename = [name '_' file '_' num2str(tol(1), '%.0e') '_' num2str(tol(NT), '%.0e')];
util.store(filename, tol, t, S, pl, sc);
