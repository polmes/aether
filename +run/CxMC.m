function CxMC(casefile, analysisfile)
	if nargin < 2
		analysisfile = mfilename;
	end
	if nargin < 1
		casefile = '';
	end
	[sc, pl, engine, S0, T, opts] = util.pre(casefile, analysisfile);

	% Analysis variables
	stdv = opts.std;
	NS = opts.samples;
	tol = opts.tolerances;

	% Random inputs
	inputs = [uq.RandomGaussian(1, stdv, true) , ... % for CL
	          uq.RandomGaussian(1, stdv, true) , ... % for CD
	          uq.RandomGaussian(1, stdv, true)];     % for Cm

	% Get # of physical cores
	NP = feature('numcores');

	% Initialize stochastic objects
	scs = repelem(SpacecraftStochastic(sc, inputs), NP); % Apollo spacecraft

	% Generate samples
	% Y = uq.LHS(inputs, NS);
	Y = uq.MC(inputs, NS);

	% Solver setup
	engine.options('RelTol', tol(1), 'AbsTol', tol(2), 'ShowWarnings', false);

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
			scs(j).update(Y(k,:));

			% Trajectory simulation
			[t, S, ie] = engine.integrate(T, S0, scs(j), pl);
			U{i,1} = t;
			U{i,2} = S;
			U{i,3} = ie;

			% Quantities of interest
			if isempty(ie)
				ie = 0;
			end
			Q(i,:) = util.getQoI(t, S, ie, scs(j), pl);
		end

		% Combine Composite variables
		U = gcat(U, 1, 1);
		Q = gcat(Q, 1, 1);
	end

	% Outputs
	U = U{1};
	Q = Q{1};

	% Save
	filename = [mfilename '_' num2str(stdv, '%.2f') '_' casefile '_' num2str(NS) '_' num2str(tol(1), '%.0e') '_' num2str(tol(2), '%.0e')];
	util.store(filename, inputs, NS, Y, U, Q, sc, pl);
end
