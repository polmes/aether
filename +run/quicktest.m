function quicktest(varargin)
	% Pre
	[sc, pl, engine, S0, T] = util.pre(varargin{:});

	% Solver setup
	engine.options('RelTol', 1e-3, 'AbsTol', 1e-5);

	% Trajectory simulation
	tic;
	[t, S, ie] = engine.integrate(T, S0, sc, pl);
	toc;

	% Post
	Q = util.getQoI(t, S, ie, sc, pl);
	disp(['Duration        = ' sprintf('%4.2f', Q(2))     ' s']);
	disp(['Range           = ' sprintf('%4.2f', Q(3)/1e3) ' km']);
	disp(['Deploy Velocity = ' sprintf('%4.2f', Q(4))     ' m/s']);
end
