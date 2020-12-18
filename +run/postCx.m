function postCx(varargin)
	%% INPUT

	% Handle different cases
	[~, ~, ~, ~, opts] = util.pre('', varargin{:});

	% Analysis variables
	name = util.constructname(extractAfter(mfilename, 'post'), {opts.case, opts.analysis});
	lim = opts.maxevery;
	NT = opts.steps;
	p = opts.polynomialorder;

	% Load data
	files = util.list(name);
	if isempty(files)
		error('No files match the provided case/name');
	end
	NF = numel(files);
	Yc = cell(NF, 1);
	Qc = cell(NF, 1);
	Uc = cell(NF, 1);
	for i = 1:NF
		data = util.open(files(i).name);
		Yc{i} = data.Y;
		Qc{i} = data.Q;
		Uc{i} = data.U;
		sc = data.sc;
		inputs = data.inputs;
	end
	Y = cell2mat(Yc);
	Q = cell2mat(Qc);
	U = cat(1, Uc{:});
	clear('data', 'Yc', 'Qc', 'Uc');

	%% PRE

	% QoI
	% [st, dur, ran, Uend, latf, lonf, maxU, maxG, maxQ, maxdq, q]
	good = find(Q(:,1) == 1);
	NS = size(Q, 1);
	NG = numel(good);
	n = floor(logspace(1, log10(NG), NT));

	% Any errors?
	disp(['Good trajectories: ' num2str(NG/NS * 100) '%']);

	% QoI of interest
	% Q = [ran, Uend, latf, lonf, maxG, maxdq, dur, q]
	% U = [t, ran, alt]
	Ygood = Y(good,:);
	Qgood = Q(good, [3 4 5 6 8 10 2 11]);
	Qgood(:,1) = Qgood(:,1) / 1e3; % range [m] to [km]
	Qgood(:,3:4) = rad2deg(Qgood(:,3:4)); % lat, lon [rad] to [deg]
	Qgood(:,6) = Qgood(:,6) / 1e4; % max heating [W/m^2] to [W/cm^2]
	Qgood(:,8) = Qgood(:,8) / 1e7; % integrated heat [J/m^2] to [kJ/cm^2]
	Ugood = cellfun(@(x) [x(:,1) x(:,2:3)/1e3], U(good), 'UniformOutput', false); % [m] to [km]
	clear('Y', 'Q', 'U');

	% Statistics
	NQ = size(Qgood, 2);
	Qmean = zeros(NT, NQ);
	Qvari = zeros(NT, NQ);
	for i = 1:NT
		Qmean(i,:) = mean(Qgood(1:n(i),:));
		Qvari(i,:) = mean((Qgood(1:n(i),:) - Qmean(i,:)).^2);
	end

	% Expectations
	disp(['Mean Range       = ' sprintf('%8.2f', Qmean(NT,1)) ' km     ']);
	disp(['Mean Velocity    = ' sprintf('%8.2f', Qmean(NT,2)) ' m/s    ']);
	disp(['Mean Max Loading = ' sprintf('%8.2f', Qmean(NT,5)) ' g0     ']);
	disp(['Mean Max Heating = ' sprintf('%8.2f', Qmean(NT,6)) ' W/cm^2 ']);
	disp(['Mean Duration    = ' sprintf('%8.2f', Qmean(NT,7)) ' s      ']);
	disp(['Mean Total Heat  = ' sprintf('%8.2f', Qmean(NT,8)) ' kJ/cm^2']);

	% Standard deviations
	Qstdv = sqrt(Qvari(NT,:));
	Qperc = Qstdv ./ Qmean(NT,:) * 100;
	disp(['StdDev Range       = ' sprintf('%7.2f', Qstdv(1)) ' km      = ' sprintf('%5.2f', Qperc(1)) '%']);
	disp(['StdDev Velocity    = ' sprintf('%7.2f', Qstdv(2)) ' m/s     = ' sprintf('%5.2f', Qperc(2)) '%']);
	disp(['StdDev Max Loading = ' sprintf('%7.2f', Qstdv(5)) ' g0      = ' sprintf('%5.2f', Qperc(5)) '%']);
	disp(['StdDev Max Heating = ' sprintf('%7.2f', Qstdv(6)) ' W/cm^2  = ' sprintf('%5.2f', Qperc(6)) '%']);
	disp(['StdDev Duration    = ' sprintf('%7.2f', Qstdv(7)) ' s       = ' sprintf('%5.2f', Qperc(7)) '%']);
	disp(['StdDev Total Heat  = ' sprintf('%7.2f', Qstdv(8)) ' kJ/cm^2 = ' sprintf('%5.2f', Qperc(8)) '%']);

	% Covariance ellipses: Range-Velocity (RV) + Loading-Heating (LH) + Duration-Heat (DQ)
	Crv = cov(Qgood(:,1:2)); % returns 2x2 "covariance matrix"
	[ellxRV, ellyRV] = covellipse(Crv, Qmean(NT,1:2)); % with 3-sigma uncertainty
	Clh = cov(Qgood(:,5:6)); % returns 2x2 "covariance matrix"
	[ellxLH, ellyLH] = covellipse(Clh, Qmean(NT,5:6)); % with 3-sigma uncertainty
	Cdq = cov(Qgood(:,7:8)); % returns 2x2 "covariance matrix"
	[ellxDQ, ellyDQ] = covellipse(Cdq, Qmean(NT,7:8)); % with 3-sigma uncertainty

	% Lower/upper bounds
	Qlostd = zeros(1, NQ);
	Qupstd = zeros(1, NQ);
	for q = 1:NQ
		Qlower = Qgood(Qgood(:,q) < Qmean(NT,q), q);
		Qupper = Qgood(Qgood(:,q) > Qmean(NT,q), q);
		Qlostd(q) = sqrt(mean((Qlower - Qmean(NT,q)).^2));
		Qupstd(q) = sqrt(mean((Qupper - Qmean(NT,q)).^2));
	end
	Qperclo = Qlostd ./ Qmean(NT,:) * 100;
	Qpercup = Qupstd ./ Qmean(NT,:) * 100;
	disp(['Lower StdDev Range       = ' sprintf('%7.2f', Qlostd(1)) ' km      = ' sprintf('%5.2f', Qperclo(1)) '%']);
	disp(['Lower StdDev Velocity    = ' sprintf('%7.2f', Qlostd(2)) ' m/s     = ' sprintf('%5.2f', Qperclo(2)) '%']);
	disp(['Lower StdDev Max Loading = ' sprintf('%7.2f', Qlostd(5)) ' g0      = ' sprintf('%5.2f', Qperclo(5)) '%']);
	disp(['Lower StdDev Max Heating = ' sprintf('%7.2f', Qlostd(6)) ' W/cm^2  = ' sprintf('%5.2f', Qperclo(6)) '%']);
	disp(['Lower StdDev Duration    = ' sprintf('%7.2f', Qlostd(7)) ' s       = ' sprintf('%5.2f', Qperclo(7)) '%']);
	disp(['Lower StdDev Total Heat  = ' sprintf('%7.2f', Qlostd(8)) ' kJ/cm^2 = ' sprintf('%5.2f', Qperclo(8)) '%']);
	disp(['Upper StdDev Range       = ' sprintf('%7.2f', Qupstd(1)) ' km      = ' sprintf('%5.2f', Qpercup(1)) '%']);
	disp(['Upper StdDev Velocity    = ' sprintf('%7.2f', Qupstd(2)) ' m/s     = ' sprintf('%5.2f', Qpercup(2)) '%']);
	disp(['Upper StdDev Max Loading = ' sprintf('%7.2f', Qupstd(5)) ' g0      = ' sprintf('%5.2f', Qpercup(5)) '%']);
	disp(['Upper StdDev Max Heating = ' sprintf('%7.2f', Qupstd(6)) ' W/cm^2  = ' sprintf('%5.2f', Qpercup(6)) '%']);
	disp(['Upper StdDev Duration    = ' sprintf('%7.2f', Qupstd(7)) ' s       = ' sprintf('%5.2f', Qpercup(7)) '%']);
	disp(['Upper StdDev Total Heat  = ' sprintf('%7.2f', Qupstd(8)) ' kJ/cm^2 = ' sprintf('%5.2f', Qpercup(8)) '%']);

	% Convergence error
	Qmerr = abs((Qmean(NT-1,:) - Qmean(NT,:)) ./ Qmean(NT,:));
	Qverr = abs((Qvari(NT-1,:) - Qvari(NT,:)) ./ Qvari(NT,:));
	disp(['Mean     Range    Error = ' sprintf('%.2e', Qmerr(1))]);
	disp(['Variance Range    Error = ' sprintf('%.2e', Qverr(1))]);
	disp(['Mean     Velocity Error = ' sprintf('%.2e', Qmerr(2))]);
	disp(['Variance Velocity Error = ' sprintf('%.2e', Qverr(2))]);
	disp(['Mean     Loading  Error = ' sprintf('%.2e', Qmerr(5))]);
	disp(['Variance Loading  Error = ' sprintf('%.2e', Qverr(5))]);
	disp(['Mean     Heating  Error = ' sprintf('%.2e', Qmerr(6))]);
	disp(['Variance Heating  Error = ' sprintf('%.2e', Qverr(6))]);
	disp(['Mean     Heat     Error = ' sprintf('%.2e', Qmerr(7))]);
	disp(['Variance Heat     Error = ' sprintf('%.2e', Qverr(7))]);
	disp(['Mean     Duration Error = ' sprintf('%.2e', Qmerr(8))]);
	disp(['Variance Duration Error = ' sprintf('%.2e', Qverr(8))]);

	% Find closest trajectories to lower/upper 3-sigma + mean range
	[~, in] = min(abs(Qgood(:,1) - (Qmean(NT,1) - 3*Qupstd(1))));
	[~, im] = min(abs(Qgood(:,1) - Qmean(NT,1)));
	[~, ix] = min(abs(Qgood(:,1) - (Qmean(NT,1) + 3*Qlostd(1))));

	% Smart indexing to reduce figure size
	nmx = [in, im, ix];
	idx = cell(1, numel(nmx));
	for k = 1:numel(nmx)
		idx{k} = zeros(numel(Ugood{nmx(k)}(:,1)), 1);
		tdf = ceil(1 ./ diff(Ugood{nmx(k)}(1:end-1,1)));
		tdf(tdf > lim) = lim;
		i = 1;
		j = 1;
		while i < numel(Ugood{nmx(k)}(:,1)) - 1
			idx{k}(j) = i;
			i = i + tdf(i);
			j = j + 1;
		end
		idx{k}(j) = numel(Ugood{nmx(k)}(:,1));
		idx{k}(j+1:end) = [];
	end

	% Lift-down period
	iini = find(diff(Ugood{im}(:,3)) > 0, 1);
	[~, iend] = min(abs(Ugood{im}(:,1) - (Ugood{im}(iini,1) + sc.tref(1))));
	[~, iidx] = min(abs([iini, iend] - idx{2}));

	% Polynomial Chaos Expansion via least-squares regression
	[C, ~, I] = uq.PCE(Ygood, Qgood, inputs, p);
	QmeanPC = C(1,:);
	QvariPC = sum(C(2:end,:).^2);
	QmerrPC = abs((QmeanPC - Qmean(NT,:)) ./ Qmean(NT,:));
	QverrPC = abs((Qvari - Qvari(NT,:)) ./ Qvari(NT,:));
	disp(['PCE Mean     Range    Error = ' sprintf('%.2e', QmerrPC(1))]);
	disp(['PCE Variance Range    Error = ' sprintf('%.2e', QverrPC(1))]);
	disp(['PCE Mean     Velocity Error = ' sprintf('%.2e', QmerrPC(2))]);
	disp(['PCE Variance Velocity Error = ' sprintf('%.2e', QverrPC(2))]);
	disp(['PCE Mean     Loading  Error = ' sprintf('%.2e', QmerrPC(5))]);
	disp(['PCE Variance Loading  Error = ' sprintf('%.2e', QverrPC(5))]);
	disp(['PCE Mean     Heating  Error = ' sprintf('%.2e', QmerrPC(6))]);
	disp(['PCE Variance Heating  Error = ' sprintf('%.2e', QverrPC(6))]);
	disp(['PCE Mean     Heat     Error = ' sprintf('%.2e', QmerrPC(7))]);
	disp(['PCE Variance Heat     Error = ' sprintf('%.2e', QverrPC(7))]);
	disp(['PCE Mean     Duration Error = ' sprintf('%.2e', QmerrPC(8))]);
	disp(['PCE Variance Duration Error = ' sprintf('%.2e', QverrPC(8))]);

	% Total Sensitivity/Sobol' Index for each QoI
	ND = size(I, 2); % = numel(in)
	TSI = zeros(ND, NQ);
	for k = 1:ND
		TSI(k,:) = sum(C(I(:,k) > 0,:).^2) ./ QvariPC;
	end
	TSI = TSI ./ sum(TSI); % normalize to 1
	labels = {'Range', 'Deploy Velocity', 'Max $g_0$ Loading', 'Max Heat Flux', 'Flight Duration', 'Total Heat Load'}; % QoI's [1 2 5 6 7 8]

	%% POST

	% Altitude vs. range
	figure;
	hold('on');
	plot(Ugood{im}(idx{2},2), Ugood{im}(idx{2},3));
	fill([Ugood{in}(idx{1},2); flipud(Ugood{ix}(idx{3},2))], [Ugood{in}(idx{1},3); flipud(Ugood{ix}(idx{3},3))], ...
		[0.000 0.447 0.741], 'FaceAlpha', 0.2, 'EdgeColor', 'none');
	set(gca, 'Children', flipud(get(gca, 'Children'))); % line plot on top
	plot(Ugood{im}(idx{2}(iidx(1):iidx(2)),2), Ugood{im}(idx{2}(iidx(1):iidx(2)),3), ...
		'Color', [0.850 0.325 0.098], 'Marker', '.', 'MarkerSize', 5);
	grid('on');
	axis('tight');
	xlabel('Range [km]');
	ylabel('Altitude [km]');
	legend(cat(1, flipud(findobj(gca, 'Type', 'Line')), findobj(gca, 'Type', 'Patch')), ...
		{'Mean range trajectory', 'Lift-down period', '3$\sigma$ range boundaries'});
	set(gcf, 'Renderer', 'painters'); % force vector render when using 'fill'

	% Scatter range-velocity
	figure;
	hold('on');
	scatter(Qgood(:,1), Qgood(:,2), 5, 'filled');
	plot(ellxRV, ellyRV);
	grid('on');
	xlabel('Range [km]');
	ylabel('Deploy Velocity [m/s]');
	legend(findobj(gca, 'Type', 'Line'), '3$\sigma$ covariance');

	% Scatter loading-heating
	figure;
	hold('on');
	scatter(Qgood(:,5), Qgood(:,6), 5, 'filled');
	plot(ellxLH, ellyLH);
	grid('on');
	xlabel('Maximum $g_0$ Loading');
	ylabel('Maximum Heating Rate [W/cm$^2$]');
	legend(findobj(gca, 'Type', 'Line'), '3$\sigma$ covariance');

	% Scatter duration-heat
	figure;
	hold('on');
	scatter(Qgood(:,7), Qgood(:,8), 5, 'filled');
	plot(ellxDQ, ellyDQ);
	grid('on');
	xlabel('Flight Duration [s]');
	ylabel('Integrated Heat Load [kJ/cm$^2$]');
	legend(findobj(gca, 'Type', 'Line'), '3$\sigma$ covariance');

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

	% Duration convergence
	figure;
	hold('on');
	grid('on');
	xlabel('Number of Samples');
	yyaxis('left');
	plot(n, Qmean(:,7), '^-', 'MarkerFaceColor', 'auto');
	ylabel('Mean Duration [s]');
	yyaxis('right');
	plot(n, Qvari(:,7), 'v-', 'MarkerFaceColor', 'auto');
	ylabel('Duration Variance');
	set(gca, 'XScale', 'log');
	xlim([0, inf]);

	% Heat convergence
	figure;
	hold('on');
	grid('on');
	xlabel('Number of Samples');
	yyaxis('left');
	plot(n, Qmean(:,8), '^-', 'MarkerFaceColor', 'auto');
	ylabel('Mean Integrated Heat Load [kJ/cm$^2$]');
	yyaxis('right');
	plot(n, Qvari(:,8), 'v-', 'MarkerFaceColor', 'auto');
	ylabel('Integrated Heat Load Variance');
	set(gca, 'XScale', 'log');
	xlim([0, inf]);

	% Total Sobol' Indices
	figure;
	bar(reordercats(categorical(labels), labels), TSI(:,[1 2 5 6 7 8]).');
	grid('on');
	legend('$C_L$', '$C_D$', '$C_m$');
	ylabel("Total Sobol' Index");

	% Set options
	set(findobj('Type', 'Legend'), 'Interpreter', 'latex');
	set(findobj('Type', 'axes'), 'FontSize', 12, 'TickLabelInterpreter', 'latex');
	set(findobj('Type', 'ColorBar'), 'TickLabelInterpreter', 'latex');
	set(findobj('Type', 'figure'), 'PaperUnits', 'centimeters', 'PaperPosition', [0 0 16 10], 'PaperSize', [16 10]);
	set(findall(findobj('Type', 'axes'), 'Type', 'Text'), 'Interpreter', 'latex');
	set(findall(findobj('Type', 'axes'), 'Type', 'Line'), 'LineWidth', 1);

	%% FINAL

	% Save figures
	names = {'altran', 'scRV', 'scLH', 'scDQ', 'scLL', 'convR', 'convV', 'convL', 'convH', 'convD', 'convQ', 'TSI'};
	figcount = numel(names); % # of figures to save
	totalfig = numel(findobj('type', 'figure'));
	formats = ['pdf', repmat({'epsc'}, [1 figcount-1])];
	for i = 1:figcount
		util.render(figure(totalfig - figcount + i), [name '_' names{i}], 'Format', formats{i});
		util.render(figure(totalfig - figcount + i), [name '_' names{i}], 'Format', 'fig');
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
