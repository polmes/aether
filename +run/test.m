function test(varargin)
	% Pre
	[sc, pl, en, S0, opts] = util.pre(varargin{:});

	% Trajectory simulation
	tic;
	[t, S, ie] = en.integrate(S0, sc, pl);
	toc;

	% Quantities of Interest
	if opts.quantities
		Q = util.getQoI(t, S, ie, sc, pl);
		disp(['Duration         = ' sprintf('%7.2f' , Q(2))          ' s']);
		disp(['Range            = ' sprintf('%7.2f' , Q(3)/1e3)      ' km']);
		disp(['Deploy Velocity  = ' sprintf('%7.2f' , Q(4))          ' m/s']);
		disp(['Deploy Latitude  = ' sprintf('%+7.2f', rad2deg(Q(5))) ' deg']);
		disp(['Deploy Longitude = ' sprintf('%+7.2f', rad2deg(Q(6))) ' deg']);
		disp(['Max Deceleration = ' sprintf('%7.2f' , Q(8))          ' g0']);
		disp(['Max Heat Flux    = ' sprintf('%7.2f' , Q(10)/1e4)     ' W/cm^2']);
		disp(['Integrated Heat  = ' sprintf('%7.2f' , Q(11)/1e7)     ' kJ/cm^2']);
	end

	% Visualization
	if opts.visualize
		[lat, lon, alt, ph, th, ps] = util.post(t, S, sc, pl);
	end

	% FlightGear
	if opts.flightgear
		util.flight3D(t, lat, lon, alt, ph, th, ps);
	end

	% Send variables to 'base' workspace for debugging
	vars = who;
	for i = 1:numel(vars)
		assignin('base', vars{i}, eval(vars{i}));
	end
end
