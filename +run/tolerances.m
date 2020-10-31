function tolerances(varargin)
	[sc, pl, engine, S0, opts] = util.pre(varargin{:});

	% Analysis variables
	tol = logspace(opts.mintol, opts.maxtol, opts.numtol);

	% Solver setup
	engine.options('ShowWarnings', false);

	% Init
	NT = numel(tol);
	t = cell(1, NT);
	S = cell(1, NT);
	ie = cell(1, NT);

	% Loop over tolerances
	for i = 1:NT
		% Tolerances
		reltol = tol(i);
		abstol = tol(i) * 1e-2;
		engine.options('RelTol', reltol, 'AbsTol', abstol);
		tolstr = ['RelTol = ' num2str(reltol, '%.0e') ', AbsTol = ' num2str(abstol, '%.0e')];

		% Trajectory simulation
		try
			tic;
			[t{i}, S{i}, ie{i}] = engine.integrate(S0, sc, pl);
			rt = toc;
			disp([tolstr ' - RunTime = ' num2str(rt, '%.2f') ' seconds']);
		catch
			warning(['Simulation failed for: ' tolstr]);
		end
	end

	% Save data
	filename = [mfilename '_' num2str(tol(1), '%.0e') '_' num2str(tol(NT), '%.0e')];
	util.store(filename, tol, t, S, pl, sc);
end
