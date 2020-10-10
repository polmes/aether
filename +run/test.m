function test(varargin)
	% Pre
	[sc, pl, engine, S0, T] = util.pre(varargin{:});

	% Solver setup
	engine.options('RelTol', 1e-3, 'AbsTol', 1e-5);

	% Trajectory simulation
	tic;
	[t, S] = engine.integrate(T, S0, sc, pl);
	toc;

	% Post
	util.post(t, S, sc, pl);
	util.flight3D(t, S, pl);

	% Send variables to 'base' workspace for debugging
	vars = who;
	for i = 1:numel(vars)
		assignin('base', vars{i}, eval(vars{i}));
	end
end
