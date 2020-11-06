function CxMC(varargin)
	% Global variables
	[~, ~, ~, S0, opts] = util.pre(varargin{:});

	% Analysis variables
	stdv = opts.std;
	NS = opts.samples;
	every = opts.stepevery;

	% Random inputs
	inputs = [uq.RandomGaussian(1, stdv, true) , ... % for CL
	          uq.RandomGaussian(1, stdv, true) , ... % for CD
	          uq.RandomGaussian(1, stdv, true)];     % for Cm

	% Get # of physical cores
	NP = feature('numcores');

	% Generate samples
	% Y = uq.LHS(inputs, NS);
	Y = uq.MC(inputs, NS);

	% Init parallel pool
	if isempty(gcp('nocreate'))
		parpool(NP);
	end

	% Parallelization
	spmd(NP)
		% Worker objects
		[sc, pl, en] = util.pre(varargin{:});

		% Initialize stochastic objects
		scs = SpacecraftStochastic(sc, inputs);

		% Solver setup
		en.options('ShowWarnings', false);

		% Indexing
		j = labindex;
		if labindex ~= NP
			NW = floor(NS / NP);
		else
			NW = NS - (NP - 1) * floor(NS / NP);
		end
		NWp = floor(NS / NP);

		% Iterate
		U = cell(NW, 1);
		Q = zeros(NW, 11);
		for i = 1:NW
			k = (j - 1) * NWp + i;
			disp(['Iteration: ' sprintf('%6d', i) ' of ' num2str(NW) newline 'Combination of random inputs #' num2str(k)]);

			% Random inputs
			scs.update(Y(k,:));

			% Trajectory simulation
			[t, S, ie] = en.integrate(S0, scs, pl);

			% Quantities of interest
			if isempty(ie)
				ie = 0;
			end
			[Q(i,:), U{i}] = util.getQoI(t, S, ie, scs, pl, every);
		end

		% Combine Composite variables
		U = gcat(U, 1, 1);
		Q = gcat(Q, 1, 1);
	end

	% Outputs
	U = U{1};
	Q = Q{1};
	sc = sc{1};
	pl = pl{1};

	% Save
	filename = [mfilename '-' char(join(varargin, '-'))];
	util.store(filename, inputs, NS, Y, U, Q, sc, pl);
end
