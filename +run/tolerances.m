function tolerances(casefile, analysisfile)
	if nargin < 2
		analysisfile = mfilename;
	end
	if nargin < 1
		casefile = '';
	end
	[sc, pl, S0, T, engine, opts] = util.pre(casefile, analysisfile);

	% Analysis variables
	tol = logspace(opts.mintol, opts.maxtol, opts.numtol);

	% Solver setup
	engine.options('ShowWarnings', false);
	if isfield(opts, 'integrator')
		engine.options('Integrator', eval(['@' opts.integrator]));
	end

	% Init
	NT = numel(tol);
	t = cell(1, NT);
	S = cell(1, NT);
	ie = zeros(1, NT);

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
			[t{i}, S{i}, ie(i)] = engine.integrate(T, S0, sc, pl);
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
