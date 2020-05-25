%% INPUT

name = 'MCAll';

inputs = [uq.PolynomialGaussLegendre(9.73e3, 11.73e3)              , ... % entry velocity about 10.73 km/s
          uq.PolynomialGaussLegendre(deg2rad(-5.9), deg2rad(-7.9)) , ... % flight path angle about -6.9 deg
          uq.PolynomialGaussHermite(0, 1)                          , ... % for density
          uq.PolynomialGaussHermite(0, 1)                         ];     % for mean free path

NS = 10000;

NP = 2;

%% PRE

% Constants
sc = Spacecraft(5860, 3.9, 4.7, [8000, 7000, 7000], 'apollomod', 7.3e3); % Apollo spacecraft
at = AtmosphereStochastic(0, 0, '24/07/1969', 12, sc, 5); % stochastic NRLMSISE
pl = Planet(6371e3, 5.97237e24, AtmosphereSample(at)); % Earth properties

% Generate samples
Y = uq.random(inputs, NS);

% Initial conditions
alt = 120e3; % always start at edge of atmosphere

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
		disp(['Iteration: ' sprintf('%6d', i) ' of ' num2str(NW)]);
		disp(['Combination of random inputs #' num2str(k)]);

		% Random inputs
		S0 = [alt, Y(k,1), Y(k,2)];
		pl.atm.update(Y(k,3), Y(k,4));

		% Trajectory simulation
		[t, S, ie] = engine.integrate(T, S0, sc, pl);
		U{i,1} = t;
		U{i,2} = S;
		U{i,3} = ie;

		% Quantities of interest
		if isempty(ie)
			ie = 0;
		end
		Q(i,:) = getQoI(t, S, ie, sc, pl);
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
filename = [name '_' num2str(q)];
util.store(filename, inputs, NS, Y, U, Q, sc, pl);
