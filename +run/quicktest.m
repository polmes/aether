function quicktest(varargin)
	% Pre
	[sc, pl, engine, S0, T] = util.pre(varargin{:});

	% Solver setup
	engine.options('RelTol', 1e-5, 'AbsTol', 1e-7);

	% Trajectory simulation
	tic;
	[t, S, ie] = engine.integrate(T, S0, sc, pl);
	toc;

	% Post
	% QoI = [st, dur, ran, Uend, latf, lonf, maxU, maxG, maxQ, maxdq, q];
	Q = util.getQoI(t, S, ie, sc, pl);
	disp(['Duration         = ' sprintf('%7.2f', Q(2))           ' s']);
	disp(['Range            = ' sprintf('%7.2f', Q(3)/1e3)       ' km']);
	disp(['Deploy Velocity  = ' sprintf('%7.2f', Q(4))           ' m/s']);
	disp(['Deploy Latitude  = ' sprintf('%+7.2f', rad2deg(Q(5))) ' deg']);
	disp(['Deploy Longitude = ' sprintf('%+7.2f', rad2deg(Q(6))) ' deg']);
	disp(['Max Deceleration = ' sprintf('%7.2f', Q(8))           ' g0']);
	disp(['Max Heat Flux    = ' sprintf('%7.2f', Q(10)/1e4)      ' W/cm^2']);
	disp(['Integrated Heat  = ' sprintf('%7.2f', Q(11)/1e7)      ' kJ/cm^2']);
end
