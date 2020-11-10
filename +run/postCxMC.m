function postCxMC(varargin)
	%% INPUT

	% Handle different cases
	[~, ~, ~, ~, opts] = util.pre('', varargin{:});

	% Analysis variables
	name = util.constructname(extractAfter(mfilename, 'post'), {opts.case, opts.analysis});
	NT = opts.steps;

	% Load data
	files = util.list(name);
	if isempty(files)
		error('No files match the provided case/name');
	end
	NF = numel(files);
	Qc = cell(NF, 1);
	Uc = cell(NF, 1);
	for i = 1:NF
		data = util.open(files(i).name);
		Qc{i} = data.Q;
		Uc{i} = data.U;
		% pl = data.pl;
	end
	Q = cell2mat(Qc);
	U = cat(1, Uc{:});
	clear('data', 'Qc', 'Uc');

	%% PRE

	% QoI
	% [st, dur, pos, Uend, maxU, maxG, maxQ, q]
	good = find(Q(:,1) == 1);
	NS = size(Q, 1);
	NG = numel(good);
	n = floor(logspace(1, log10(NG), NT));

	% Any errors?
	disp(['Good trajectories: ' num2str(NG/NS * 100) '%']);

	% QoI of interest
	% [ran, Uend, latf, lonf, maxG, maxdq]
	Qgood = Q(good, [3 4 5 6 8 10]);
	Qgood(:,1) = Qgood(:,1) / 1e3; % range [m] to [km]
	Qgood(:,3:4) = rad2deg(Qgood(:,3:4)); % lat, lon [rad] to [deg]
	Qgood(:,6) = Qgood(:,6) / 1e4; % max heating [W/m^2] to [W/cm^2]
	Ugood = cellfun(@(x) x(:,2:4) / 1e3, U(good), 'UniformOutput', false); % [m, m/s] to [km, km/s]
	clear('Q', 'U');

	% Statistics
	NQ = size(Qgood, 2);
	Qmean = zeros(NT, NQ);
	Qvari = zeros(NT, NQ);
	for i = 1:NT
		Qmean(i,:) = mean(Qgood(1:n(i),:));
		Qvari(i,:) = mean((Qgood(1:n(i),:) - Qmean(i,:)).^2);
	end

	% Standard deviations
	Qstdv = sqrt(Qvari(NT,:));
	Qperc = Qstdv ./ Qmean(NT,:) * 100;
	disp(['StdDev Range       = ' num2str(Qstdv(1), '%.2f') ' km     = ' num2str(Qperc(1), '%.2f') '%']);
	disp(['StdDev Velocity    = ' num2str(Qstdv(2), '%.2f') ' m/s    = ' num2str(Qperc(2), '%.2f') '%']);
	disp(['StdDev Max Loading = ' num2str(Qstdv(5), '%.2f') ' g0     = ' num2str(Qperc(5), '%.2f') '%']);
	disp(['StdDev Max Heating = ' num2str(Qstdv(6), '%.2f') ' W/cm^2 = ' num2str(Qperc(6), '%.2f') '%']);

	% Covariance ellipses: Range-Velocity (RV) + Loading-Heating (LH)
	Crv = cov(Qgood(:,1:2)); % returns 2x2 "covariance matrix"
	[ellxRV, ellyRV] = covellipse(Crv, Qmean(NT,1:2)); % with 3-sigma uncertainty
	Clh = cov(Qgood(:,5:6)); % returns 2x2 "covariance matrix"
	[ellxLH, ellyLH] = covellipse(Clh, Qmean(NT,5:6)); % with 3-sigma uncertainty

	% Convergence error
	Qmerr = (Qmean(NT-1,:) - Qmean(NT,:)) ./ Qmean(NT,:);
	Qverr = (Qvari(NT-1,:) - Qvari(NT,:)) ./ Qvari(NT,:);
	disp(['Mean     range    error = ' num2str(Qmerr(1), '%.2e')]);
	disp(['Variance range    error = ' num2str(Qverr(1), '%.2e')]);
	disp(['Mean     velocity error = ' num2str(Qmerr(2), '%.2e')]);
	disp(['Variance velocity error = ' num2str(Qverr(2), '%.2e')]);
	disp(['Mean     loading  error = ' num2str(Qmerr(5), '%.2e')]);
	disp(['Variance loading  error = ' num2str(Qverr(5), '%.2e')]);
	disp(['Mean     heating  error = ' num2str(Qmerr(6), '%.2e')]);
	disp(['Variance heating  error = ' num2str(Qverr(6), '%.2e')]);

	% Find closest trajectories to 3-sigma min/max + mean range
	[~, in]  =  min(abs(Qgood(:,1) - (Qmean(NT,1) - 3*Qstdv(1))));
	[~, im]  =  min(abs(Qgood(:,1) - Qmean(NT,1)));
	[~, ix]  =  min(abs(Qgood(:,1) - (Qmean(NT,1) + 3*Qstdv(1))));

	%% POST

	% Altitude vs. range
	figure;
	hold('on');
	plot(Ugood{im}(:,1), Ugood{im}(:,2));
	fill([Ugood{in}(:,1); flipud(Ugood{ix}(:,1))], [Ugood{in}(:,2); flipud(Ugood{ix}(:,2))], ...
		lines(1), 'FaceAlpha', 0.15, 'EdgeColor', 'none');
	xlim([0, inf]);
	ylim([-inf, +inf]);
	xlabel('Range [km]');
	ylabel('Altitude [km]');
	legend('Mean range trajectory', '3-$\sigma$ range boundaries');

	% Scatter range-velocity
	figure;
	hold('on');
	scatter(Qgood(:,1), Qgood(:,2), 5, 'filled');
	plot(ellxRV, ellyRV);
	grid('on');
	xlabel('Range [km]');
	ylabel('Deploy Velocity [m/s]');

	% Scatter loading-heating
	figure;
	hold('on');
	scatter(Qgood(:,5), Qgood(:,6), 5, 'filled');
	plot(ellxLH, ellyLH);
	grid('on');
	xlabel('Maximum $g_0$ Loading');
	ylabel('Maximum Heating Rate [W/cm$^2$]');

	% Scatter landing location
	figure;
	scatter(Qgood(:,4), Qgood(:,3), 5, 'x');
	grid('on');
	xlabel('Longitude [$^\circ$]');
	ylabel('Latitude [$^\circ$]');

	% Range convergence
	figure;
	hold('on');
	grid('on');
	xlabel('Number of Samples');
	yyaxis('left');
	plot(n, Qmean(:,1), '^-', 'MarkerFaceColor', 'auto');
	ylabel('Mean Range [km]');
	yyaxis('right');
	plot(n, Qvari(:,1), 'v-', 'MarkerFaceColor', 'auto');
	ylabel('Range Variance');
	set(gca, 'XScale', 'log');
	xlim([0, inf]);

	% Velocity convergence
	figure;
	hold('on');
	grid('on');
	xlabel('Number of Samples');
	yyaxis('left');
	plot(n, Qmean(:,2), '^-', 'MarkerFaceColor', 'auto');
	ylabel('Mean Velocity [m/s]');
	yyaxis('right');
	plot(n, Qvari(:,2), 'v-', 'MarkerFaceColor', 'auto');
	ylabel('Velocity Variance');
	set(gca, 'XScale', 'log');
	xlim([0, inf]);

	% Loading convergence
	figure;
	hold('on');
	grid('on');
	xlabel('Number of Samples');
	yyaxis('left');
	plot(n, Qmean(:,5), '^-', 'MarkerFaceColor', 'auto');
	ylabel('Mean Maximum $g_0$ Loading');
	yyaxis('right');
	plot(n, Qvari(:,5), 'v-', 'MarkerFaceColor', 'auto');
	ylabel('Maximum $g_0$ Loading Variance');
	set(gca, 'XScale', 'log');
	xlim([0, inf]);

	% Heating convergence
	figure;
	hold('on');
	grid('on');
	xlabel('Number of Samples');
	yyaxis('left');
	plot(n, Qmean(:,6), '^-', 'MarkerFaceColor', 'auto');
	ylabel('Mean Maximum Heating Rate [W/cm$^2$]');
	yyaxis('right');
	plot(n, Qvari(:,6), 'v-', 'MarkerFaceColor', 'auto');
	ylabel('Maximum Heating Rate Variance');
	set(gca, 'XScale', 'log');
	xlim([0, inf]);

	% Set options
	set(findobj('Type', 'Legend'), 'Interpreter', 'latex');
	set(findobj('Type', 'axes'), 'FontSize', 12, 'TickLabelInterpreter', 'latex');
	set(findobj('Type', 'ColorBar'), 'TickLabelInterpreter', 'latex');
	set(findobj('Type', 'figure'), 'PaperUnits', 'centimeters', 'PaperPosition', [0 0 16 10]);
	set(findall(findobj('Type', 'axes'), 'Type', 'Text'), 'Interpreter', 'latex');
	set(findall(findobj('Type', 'axes'), 'Type', 'Line'), 'LineWidth', 1);

	%% FINAL

	% Save figures
	names = {'altran', 'scRV', 'scLH', 'scLL', 'convR', 'convV', 'convL', 'convH'};
	figcount = numel(names); % # of figures to save
	totalfig = numel(findobj('type', 'figure'));
	for i = 1:figcount
		util.render(figure(totalfig - figcount + i), [name '_' names{i}]);
	end

	%% UTIL

	% Plot covariance ellipse
	function [x, y] = covellipse(C, mu, err)
		if nargin < 1
			error('Not enough input arguments');
		elseif nargin < 4
			if nargin < 2 || isempty(mu)
				mu = [0, 0];
			end
			if nargin < 3 || isempty(err)
				err = 3; % # of standard deviations
			end
		else
			error('Too many input arguments');
		end

		theta = linspace(0, 2*pi, 360);
		[eigvec, eigval] = eig(C);

		X = eigvec * err * sqrt(eigval) * [cos(theta); sin(theta)];
		x = mu(1) + X(1,:);
		y = mu(2) + X(2,:);
	end
end
