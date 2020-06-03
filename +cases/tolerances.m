% Load inputs
eval(['cases.' mfilename '_inputs']);

% Load global constants
constants;

% Initialize objects
sc = Spacecraft(apollo.m, apollo.L, apollo.R, apollo.I, file, apollo.deploy); % Apollo spacecraft
at = AtmosphereNRLMSISE(atm.lat, atm.lon, atm.date, atm.hrs); % standard NRLMSISE
pl = Planet(earth.R, earth.M, at); % Earth properties

% Initial conditions
S0 = [alt, Uinf, gamma];

% Constant parameters
T = 2000; % max integration time

% Init
NT = numel(tol);
t = cell(1, NT);
S = cell(1, NT);
ie = zeros(1, NT);

% Loop over tolerances
for i = 1:NT
	engine = Engine('RelTol', tol(i), 'AbsTol', tol(i) * 1e-2, 'ShowWarnings', false);

	% Trajectory simulation
	tic;
	[t{i}, S{i}, ie(i)] = engine.integrate(T, S0, sc, pl);
	toc;
end

% Save data
filename = [mfilename '_' file '_' num2str(tol(1), '%.0e') '_' num2str(tol(NT), '%.0e')];
util.store(filename, tol, t, S, pl, sc);
