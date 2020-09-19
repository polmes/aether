% Load inputs
eval(['cases.' mfilename '_inputs']);

% Load global constants
constants;

% Random inputs
inputs = [uq.RandomGaussian(1, stdv, true) , ... % for CL
          uq.RandomGaussian(1, stdv, true) , ... % for CD
          uq.RandomGaussian(1, stdv, true)];     % for Cm

% Get # of physical cores
NP = feature('numcores');

% Initialize objects
sc = repelem(SpacecraftStochastic(apollo.m, apollo.L, apollo.R, apollo.I, file, apollo.deploy, inputs), NP); % Apollo spacecraft
at = AtmosphereNRLMSISE(atm.lat, atm.lon, atm.date, atm.hrs); % standard NRLMSISE
pl = Planet(earth.R, earth.M, at); % Earth properties

% Generate samples
% Y = uq.LHS(inputs, NS);
Y = uq.MC(inputs, NS);

% Solver setup
S0 = [alt, Uinf, gamma];
engine = Engine('RelTol', tol(1), 'AbsTol', tol(2), 'ShowWarnings', false);

% Init parallel pool
if isempty(gcp('nocreate'))
	parpool(NP);
end

% Parallelization
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

% Save
filename = [mfilename '_' num2str(stdv, '%.2f') '_' file '_' num2str(NS) '_' num2str(tol(1), '%.0e') '_' num2str(tol(2), '%.0e')];
util.store(filename, inputs, NS, Y, U, Q, sc, pl);
