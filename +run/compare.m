function compare(varargin)
	% Input
	[~, ~, ~, ~, opts] = util.pre('', varargin{:});
	cases = opts.cases;
	leg = opts.legend;
	lim = opts.maxevery;
	name = util.constructname(mfilename, cat(1, varargin, cases));

	% Number of figures
	Nfig = numel(findobj('type', 'figure'));
	Nnew = 5;

	% Init figures
	for k = 1:Nnew
		figure(Nfig + k);
		hold('on');
	end

	% MATLAB colors
	col = lines(7); % the 7 default colors in default order
	col = col(1 + rem((1:4:7*4) - 1, 7), :); % the 7 default colors skipping 4 at a time to match plots below

	% Simulate each trajectory and postprocess results
	for k = 1:numel(cases)
		disp(['Case #' num2str(k) ': ' cases{k}]);

		% Pre
		[sc, pl, en, S0] = util.pre(cases{k});
		en.options('ShowWarnings', false);

		% Trajectory
		[t, S, ie, te] = en.integrate(S0, sc, pl);

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
		[~, ~, alt, ~, ~, ~, ran, vel, Kn, M, AoA, CL, CD, CLv] = util.post(t, S, sc, pl, false);
		ran = ran / 1e3; % [m] -> [km]
		alt = alt / 1e3; % [m] -> [km]
		vel = vel / 1e3; % [m/s] -> [km/s]

		% Smart indexing to reduce figure size
		idx = zeros(numel(t), 1);
		tdf = ceil(1 ./ diff(t(1:end-1)));
		tdf(tdf > lim) = lim;
		i = 1;
		j = 1;
		while i < numel(t) - 1
			idx(j) = i;
			i = i + tdf(i);
			j = j + 1;
		end
		idx(j) = numel(t);
		idx(j+1:end) = [];

		% Find lift-down period
		[~, iini] = min(abs(t - te(find(ie == 4, 1))));
		[~, iend] = min(abs(t - (t(iini) + sc.tref(1))));
		[~, iidx] = min(abs([iini, iend] - idx));

		% Plot altitude vs. range
		figure(Nfig + 1);
		plot(ran(idx), alt(idx));
		plot(ran(idx(iidx(1):iidx(2))), alt(idx(iidx(1):iidx(2))), 'Color', 'k', 'Marker', '.', 'MarkerSize', 5);
		plot(ran(igmax), alt(igmax), 'Color', 'k', 'Marker', 'v');
		plot(ran(iqmax), alt(iqmax), 'Color', 'k', 'Marker', '^');

		% Plot altitude vs. velocity
		figure(Nfig + 2);
		plot(vel(idx), alt(idx));
		plot(vel(idx(iidx(1):iidx(2))), alt(idx(iidx(1):iidx(2))), 'Color', 'k', 'Marker', '.', 'MarkerSize', 5);
		plot(vel(igmax), alt(igmax), 'Color', 'k', 'Marker', 'v');
		plot(vel(iqmax), alt(iqmax), 'Color', 'k', 'Marker', '^');

		% Plot Knudsen + Mach vs. time
		figure(Nfig + 3);
		yyaxis('left');
		plot(t(idx), Kn(idx));
		yyaxis('right');
		plot(t(idx), M(idx));

		% Plot total AoA vs. time
		figure(Nfig + 4);
		plot(t(idx), rad2deg(AoA(idx)), 'Color', col(1 + rem(k-1, 7), :));

		% Plot aerodynamic coefficients vs. time
		figure(Nfig + 5);
		plot(t(idx), abs(CL(idx)), '-', 'Color', col(1 + rem(k-1, 7), :));
		plot(t(idx), CD(idx), '--', 'Color', col(1 + rem(k-1, 7), :));
		plot(t(idx), -CLv(idx), ':', 'Color', col(1 + rem(k-1, 7), :));
	end

	% Finish figures
	figure(Nfig + 1);
	xlabel('Range [km]');
	ylabel('Altitude [km]');
	set(get(gca, 'XAxis'), 'Exponent', 0);
	figure(Nfig + 2);
	xlabel('Inertial Velocity [km/s]');
	ylabel('Altitude [km]');
	for k = 1:2
		figure(Nfig + k);
		ch = get(gca, 'Children');
		if numel(leg) > 1
			legend(cat(1, flipud(ch(4:4:end)), flipud(ch(1:3))), cat(1, leg, 'Lift-down period', 'Maximum deceleration', 'Maximum heating'), 'Location', 'best');
		else
			legend(flipud(ch(1:3)), {'Lift-down period', 'Maximum deceleration', 'Maximum heating'}, 'Location', 'best');
		end
	end
	figure(Nfig + 3);
	xlim([0, inf]);
	xlabel('Time [s]');
	yyaxis('left');
	set(gca, 'YScale', 'log');
	ylabel('Knudsen');
	yyaxis('right');
	ylabel('Mach');
	if numel(leg) > 1
		legend(leg);
	end
	figure(Nfig + 4);
	xlim([0, inf]);
	xlabel('Time [s]');
	ylabel('Total Angle of Attack [$^\circ$]');
	if numel(leg) > 1
		legend(leg, 'Location', 'northwest');
	end
	figure(Nfig + 5);
	xlim([0, inf]);
	xlabel('Time [s]');
	ylabel('Aerodynamic Coefficient');
	legCx = {'$|C_L|$', '$C_D$', '$C_{L\,v}$'};
	if numel(leg) > 1
		leg2D = strcat(repmat(leg, [1 3]), {', '}, repmat(legCx, [numel(cases) 1])).';
		legend(leg2D(:), 'Location', 'northoutside', 'NumColumns', numel(cases));
	else
		legend(legCx, 'Location', 'northoutside');
	end

	% Set options
	set(findobj('Type', 'Legend'), 'Interpreter', 'latex');
	set(findobj('Type', 'Title'), 'Interpreter', 'latex');
	set(findobj('Type', 'axes'), 'FontSize', 12, 'TickLabelInterpreter', 'latex', 'XGrid', 'on', 'YGrid', 'on');
	set(findobj('Type', 'ColorBar'), 'TickLabelInterpreter', 'latex');
	set(findobj('Type', 'figure'), 'Renderer', 'painters', 'PaperUnits', 'centimeters', 'PaperPosition', [0 0 16 10], 'PaperSize', [16 10]);
	set(findall(findobj('Type', 'axes'), 'Type', 'Text'), 'Interpreter', 'latex');
	set(findall(findobj('Type', 'axes'), 'Type', 'Line'), 'LineWidth', 1, 'MarkerFaceColor', 'auto');

	% Save figures
	names = {'altran', 'altvel', 'KnM', 'AoA', 'Cx'};
	for k = 1:Nnew
		% Fix figure size if legend does not fit
		hleg = get(get(figure(Nfig + k), 'CurrentAxes'), 'Legend');
		if ~isempty(hleg)
			idxpos = hleg.Position(3:4) - 1 > 0;
			if any(idxpos)
				prepos = get(figure(Nfig + k), 'PaperPosition');
				newpos = prepos(3:4) + prepos(3:4) .* idxpos .* (hleg.Position(3:4) - 1 + 0.2);
				set(figure(Nfig + k), 'PaperPosition', [0 0 newpos]);
			end
		end

		% Render vector image
		util.render(figure(Nfig + k), [name '_' names{k}]);
	end
end
