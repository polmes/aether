%% INPUT

name = 'Cx_MC';

stdv = 0.05;

inputs = [uq.RandomGaussian(1, stdv, true) , ... % for CL
          uq.RandomGaussian(1, stdv, true) , ... % for CD
          uq.RandomGaussian(1, stdv, true)];     % for Cm

% inputs = [uq.RandomUniform(-0.05, 0.05) , ... % for CL
%           uq.RandomUniform(-0.10, 0.10) , ... % for CD
%           uq.RandomUniform(-0.01, 0.01)];     % for Cm

NS = 3000;

tol = [1e-3, 1e-5];

file = 'apollomod';

%% PRE

% Get # of physical cores
NP = feature('numcores');

% Constants
sc = repelem(SpacecraftStochastic(5860, 3.9, 4.7, [8000, 7000, 7000], file, 7.3e3, inputs), NP); % Apollo spacecraft
at = AtmosphereNRLMSISE(0, 0, '24/07/1969', 12); % standard NRLMSISE
pl = Planet(6371e3, 5.97237e24, at); % Earth properties

% Generate samples
% Y = uq.LHS(inputs, NS);
Y = uq.MC(inputs, NS);

% Initial conditions (from Apollo 4, ignoring lat/lon)
alt = 122e3; % [m] ~ 400k ft, always start at edge of atmosphere
Uinf = 11140; % [m/s] ~ 36545 ft/s
gamma = deg2rad(-7.01);
S0 = [alt, Uinf, gamma];

% Solver parameters
T = 2000; % max integration time
engine = Engine('RelTol', tol(1), 'AbsTol', tol(2), 'ShowWarnings', false);

%% MAIN

% Init parallel pool
if isempty(gcp('nocreate'))
	parpool(NP);
end

spmd(NP)
	j = labindex;
	if labindex ~= NP
		NW = floor(NS / NP);
	else
		NW = NS - (NP - 1) * floor(NS / NP);
	end
	NWp = floor(NS / NP);

	U = cell(NW, 3);
	Q = zeros(NW, 8);
	for i = 1:NW
		k = (j - 1) * NWp + i;
		disp(['Iteration: ' sprintf('%6d', i) ' of ' num2str(NW) newline 'Combination of random inputs #' num2str(k)]);

		% Random inputs
		sc(j).update(Y(k,:));

		% Trajectory simulation
		[t, S, ie] = engine.integrate(T, S0, sc(j), pl);
		U{i,1} = t;
		U{i,2} = S;
		U{i,3} = ie;

		% Quantities of interest
		if isempty(ie)
			ie = 0;
		end
		Q(i,:) = getQoI(t, S, ie, sc(j), pl);
	end

	% Combine Composite variables
	U = gcat(U, 1, 1);
	Q = gcat(Q, 1, 1);
end

% Outputs
U = U{1};
Q = Q{1};

%% POST

% Save
filename = [name '_' num2str(stdv, '%.2f') '_' file '_' num2str(NS) '_' num2str(tol(1)) '_' num2str(tol(2))];
util.store(filename, inputs, NS, Y, U, Q, sc, pl);
