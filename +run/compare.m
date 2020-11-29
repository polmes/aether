function compare(varargin)
	% Input
	[~, ~, ~, ~, opts] = util.pre('', varargin{:});
	cases = opts.cases;
	leg = opts.legend;
	name = util.constructname(mfilename, cat(1, varargin, cases));

	% Number of figures
	Nfig = numel(findobj('type', 'figure'));
	Nnew = 3;

	% Init figures
	for k = 1:Nnew
		figure(Nfig + k);
		hold('on');
	end

	% Simulate each trajectory and postprocess results
	for k = 1:numel(cases)
		disp(['Case #' num2str(k) ': ' cases{k}]);

		% Pre
		[sc, pl, en, S0] = util.pre(cases{k});
		en.options('ShowWarnings', false);

		% Trajectory
		[t, S, ie] = en.integrate(S0, sc, pl);

		% Quantities of Interest
		[Q, ~, igmax, iqmax] = util.getQoI(t, S, ie, sc, pl);
		disp(['Duration         = ' sprintf('%7.2f' , Q(2))          ' s']);
		disp(['Range            = ' sprintf('%7.2f' , Q(3)/1e3)      ' km']);
		disp(['Deploy Velocity  = ' sprintf('%7.2f' , Q(4))          ' m/s']);
		disp(['Deploy Latitude  = ' sprintf('%+7.2f', rad2deg(Q(5))) ' deg']);
		disp(['Deploy Longitude = ' sprintf('%+7.2f', rad2deg(Q(6))) ' deg']);
		disp(['Max Deceleration = ' sprintf('%7.2f' , Q(8))          ' g0']);
		disp(['Max Heat Flux    = ' sprintf('%7.2f' , Q(10)/1e4)     ' W/cm^2']);
		disp(['Integrated Heat  = ' sprintf('%7.2f' , Q(11)/1e7)     ' kJ/cm^2']);

		% Variables
		[~, ~, alt, ~, ~, ~, ran, vel, Kn, M] = util.post(t, S, sc, pl, false);
		ran = ran / 1e3; % [m] -> [km]
		alt = alt / 1e3; % [m] -> [km]
		vel = vel / 1e3; % [m/s] -> [km/s]

		% Find lift-down period
		iini = find(diff(alt) > 0, 1);
		[~, iend] = min(abs(t - (t(iini) + sc.tref(1))));

		% Plot altitude vs. range
		figure(Nfig + 1);
		plot(ran, alt);
		plot(ran(iini:iend), alt(iini:iend), 'Color', 'k', 'Marker', '.', 'MarkerSize', 5);
		plot(ran(igmax), alt(igmax), 'Color', 'k', 'Marker', 'v');
		plot(ran(iqmax), alt(iqmax), 'Color', 'k', 'Marker', '^');

		% Plot altitude vs. velocity
		figure(Nfig + 2);
		plot(vel, alt);
		plot(vel(iini:iend), alt(iini:iend), 'Color', 'k', 'Marker', '.', 'MarkerSize', 5);
		plot(vel(igmax), alt(igmax), 'Color', 'k', 'Marker', 'v');
		plot(vel(iqmax), alt(iqmax), 'Color', 'k', 'Marker', '^');

		% Plot Knudsen + Mach vs. time
		figure(Nfig + 3);
		yyaxis('left');
		plot(t, Kn);
		yyaxis('right');
		plot(t, M);
	end

	% Finish figures
	figure(Nfig + 1);
	xlabel('Range [km]');
	ylabel('Altitude [km]');
	figure(Nfig + 2);
	xlabel('Inertial Velocity [km/s]');
	ylabel('Altitude [km]');
	for k = 1:2
		figure(Nfig + k);
		ch = get(gca, 'Children');
		legend(cat(1, flipud(ch(4:4:end)), flipud(ch(1:3))), cat(1, leg, 'Lift-down period', 'Maximum deceleration', 'Maximum heating'));
	end
	figure(Nfig + 3);
	xlim([0, inf]);
	xlabel('Time [s]');
	yyaxis('left');
	set(gca, 'YScale', 'log');
	ylabel('Knudsen');
	yyaxis('right');
	ylabel('Mach');
	legend(leg);

	% Set options
	set(findobj('Type', 'Legend'), 'Interpreter', 'latex');
	set(findobj('Type', 'Title'), 'Interpreter', 'latex');
	set(findobj('Type', 'axes'), 'FontSize', 12, 'TickLabelInterpreter', 'latex', 'XGrid', 'on', 'YGrid', 'on');
	set(findobj('Type', 'ColorBar'), 'TickLabelInterpreter', 'latex');
	set(findobj('Type', 'figure'), 'Renderer', 'painters', 'PaperUnits', 'centimeters', 'PaperPosition', [0 0 16 10], 'PaperSize', [16 10]);
	set(findall(findobj('Type', 'axes'), 'Type', 'Text'), 'Interpreter', 'latex');
	set(findall(findobj('Type', 'axes'), 'Type', 'Line'), 'LineWidth', 1, 'MarkerFaceColor', 'auto');

	% Save figures
	names = {'altran', 'altvel', 'KnM'};
	for k = 1:Nnew
		util.render(figure(Nfig + k), [name '_' names{k}]);
	end
end
