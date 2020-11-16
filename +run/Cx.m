function Cx(varargin)
	% Global variables
	[~, ~, ~, S0, opts] = util.pre(varargin{:});

	% Analysis variables
	stdv = opts.std;
	NS = opts.samples;
	every = opts.stepevery;
	Ms = opts.mach;
	Kns = opts.knudsen;

	% Random inputs
	inputs = [uq.RandomGaussian(1, stdv, true) , ... % for CL
	          uq.RandomGaussian(1, stdv, true) , ... % for CD
	          uq.RandomGaussian(1, stdv, true)];     % for Cm

	% Get # of physical cores
	NP = feature('numcores');

	% Generate samples
	switch opts.sampling
		case 'MC'
			Y = uq.MC(inputs, NS);
		case 'LHS'
			Y = uq.LHS(inputs, NS);
		otherwise
			util.exception('Unknown stochastic sampling method provided');
	end

	% Init parallel pool with unique job storage location
	if isempty(gcp('nocreate'))
		storage = fullfile(tempdir, char(java.util.UUID.randomUUID));
		mkdir(storage);
		pc = parcluster;
		pc.JobStorageLocation = storage;
		parpool(pc, NP);
	end

	% Parallelization
	spmd(NP)
		% Worker objects
		[sc, pl, en] = util.pre(varargin{:});

		% Initialize stochastic objects
		scs = SpacecraftStochastic(sc, inputs, Ms, Kns);

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
	filename = util.constructname(mfilename, varargin);
	util.store(filename, inputs, NS, Y, U, Q, sc, pl);
end
