%% INPUT

name = 'MCAtm';

inputs = [uq.RandomGaussian(0, 1) , ... % for density
          uq.RandomGaussian(0, 1)];     % for mean free path

NS = 10;

d = 20; % set to stay somehwat accurate

NP = 2;

%% PRE

% Constants
sc = Spacecraft(5860, 3.9, 4.7, [8000, 7000, 7000], 'apollomod', 7.3e3); % Apollo spacecraft
at = AtmosphereStochastic(0, 0, '24/07/1969', 12, sc, 5); % stochastic NRLMSISE
clear('pl');
pl(NP) = Planet(6371e3, 5.97237e24, AtmosphereProcess(at, d)); % Earth properties
for i = 1:NP-1
	pl(i) = Planet(6371e3, 5.97237e24, AtmosphereProcess(at, d)); % Earth properties
end

% Generate samples
Y = uq.MC(inputs, NS, d);

% Initial conditions
alt = 120e3; % always start at edge of atmosphere
Uinf = 10.73e3;
gamma = deg2rad(-6.9);
S0 = [alt, Uinf, gamma];

% Solver parameters
T = 2000; % max integration time
engine = Engine('RelTol', 1e-2, 'AbsTol', 1e-4, 'ShowWarnings', false);

%% MAIN

% Init parallel pool
if isempty(gcp('nocreate'))
	parpool(NP);
end

spmd(NP)
	j = labindex;
	if j ~= NP
		NW = floor(NS / NP);
	else
		NW = NS - (NP - 1) * floor(NS / NP);
	end
	NWp = floor(NS / NP);

	U = cell(NW, 3);
	Q = zeros(NW, 8);
	for i = 1:NW
		k = (j - 1) * NWp + i;
		disp(['Iteration: ' sprintf('%6d', i) ' of ' num2str(NW)]);
		disp(['Combination of random inputs #' num2str(k)]);

		% Random inputs
		pl(j).atm.update(Y(k,1:d), Y(k,d+1:2*d));

		% Trajectory simulation
		[t, S, ie] = engine.integrate(T, S0, sc, pl(j));
		U{i,1} = t;
		U{i,2} = S;
		U{i,3} = ie;

		% Quantities of interest
		Q(i,:) = getQoI(t, S, ie, sc, pl(j));
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
filename = [name '_' num2str(NS)];
util.store(filename, NS, Y, U, Q, sc, pl);
