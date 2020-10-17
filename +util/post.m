function [lat, lon, alt, ph, th, ps] = post(t, S, sc, pl)
	% Variables
	x = S(:,1); y = S(:,2); z = S(:,3);
	q0 = S(:,4); q1 = S(:,5); q2 = S(:,6); q3 = S(:,7);
	u = S(:,8); v = S(:,9); w = S(:,10);
	p = S(:,11); q = S(:,12); r = S(:,13);
	N = numel(t);

	% XYZ -> LLA + Range
	[lat, lon, alt, rad, Lie] = pl.xyz2lla(x, y, z, t);
	ran = pl.greatcircle(rad(1), lat(1), lon(1), rad, lat, lon);

	% ECI -> ECEF
	X = Lie * reshape([x, y, z].', [], 1);
	xE = -X(3:3:end); yE = X(1:3:end); zE = -X(2:3:end);

	% Euler angles
	[ph, th, ps, Lvb] = quaternion2euler(q0, q1, q2, q3, lat, lon, Lie);

	% Absolute velocity
	Umag = sqrt(sum([u, v, w].^2, 2));

	% Environment
	[~, MFP, a] = pl.atm.trajectory(t, alt, lat, lon);

	% Knudsen number
	Kn = MFP / sc.L;

	if size(S, 2) > 13
		% Relative velocity
		Urel = reshape([u, v, w].', [], 1) - Lvb * reshape(cat(2, pl.atmspeed(rad, lat), zeros(N, 1), zeros(N, 1)).', [], 1);
		Uinf = sqrt(sum(reshape(Urel.^2, 3, []))).';

		% [NB] = B -> N
		delta = S(:,14);
		i1 = 1:3:(1+(N-1)*3);
		i2 = 2:3:(2+(N-1)*3);
		i3 = 3:3:(3+(N-1)*3);
		i = [i1, i2, i2, i3, i3];
		j = [i1, i2, i3, i2, i3];
		k = [ones(N, 1); cos(delta); sin(delta); -sin(delta); cos(delta)];
		Lbn = sparse(i, j, k);

		% Velocity in nominal frame
		U = Lbn * Urel;

		% (Total) Angle of Attack
		Uyz = U(3:3:end) .* sqrt((U(2:3:end) ./ U(3:3:end)).^2 + 1);
		AoA = atan2(Uyz, U(1:3:end));
	else
		% No relative velocity
		Uinf = Umag;
		AoA = atan2(w, u);
	end

	% Mach number
	M = Uinf ./ a;

	% Aerodynamic coefficients
	CL = sc.Cx('CL', AoA, M, Kn);
	CD = sc.Cx('CD', AoA, M, Kn);

	% Generate sphere
	NP = 100;
	lats = linspace(-pi/2, +pi/2, NP).';
	lons = linspace(0, 2*pi, NP); % to conform with available topography
	X = pl.R * cos(lats) * cos(lons);
	Y = pl.R * cos(lats) * sin(lons);
	Z = pl.R * sin(lats) * ones(size(lons));
	topo = load('topo.mat'); % load Earth topography

	% X-Y-Z
	figure;
	hold('on');
	surface(X/1e3, Y/1e3, Z/1e3, 'FaceColor', 'texturemap', 'CData', topo.topo, 'EdgeColor', 'none', 'FaceLighting', 'gouraud');
	colormap(topo.topomap1);
	plot3(xE/1e3, yE/1e3, zE/1e3, 'Color', 'red');
	xlabel('$X$ [km]');
	ylabel('$Y$ [km]');
	zlabel('$Z$ [km]');
	axis('equal');
	view(3);

	% Trajectory vs. time
	figure;
	grid('on');
	xlabel('Time [s]');
	yyaxis('left');
	plot(t, alt / 1e3);
	ylabel('Altitude [km]');
	yyaxis('right');
	plot(t, ran / 1e3);
	ylabel('Range [km]');
	xlim([0 inf]);

	% Altitude vs. velocity
	figure;
	plot(Umag, alt / 1e3);
	grid('on');
	xlabel('Velocity [m/s]');
	ylabel('Altitude [km]');

	% Altitude + Mach vs. range
	figure;
	grid('on');
	xlabel('Range [km]');
	yyaxis('left');
	plot(ran / 1e3, alt / 1e3);
	ylabel('Altitude [km]')
	yyaxis('right');
	plot(ran / 1e3, M);
	ylabel('Mach');
	xlim([0 inf]);

	% Rarefaction + AoA vs. time
	figure;
	grid('on');
	xlabel('Time [s]');
	yyaxis('left');
	plot(t, rad2deg(AoA));
	ylabel('Angle of Attack [$^\circ$]');
	yyaxis('right');
	plot(t, Kn);
	ylabel('Knudsen');
	set(gca, 'YScale', 'log');
	xlim([0 inf]);

	% Aerodynamics vs. time
	figure;
	hold('on');
	plot(t, CL);
	plot(t, CD);
	grid('on');
	xlim([0 inf]);
	xlabel('Time [s]');
	ylabel('Coefficient');
	legend('$C_L$', '$C_D$');

	% Attitude vs. time
	figure;
	hold('on');
	plot(t, rad2deg(ph));
	plot(t, rad2deg(th));
	plot(t, rad2deg(ps));
	grid('on');
	xlim([0 inf]);
	xlabel('Time [s]');
	ylabel('Attitide Angle [$^\circ$]');
	legend('$\phi$', '$\theta$', '$\psi$');

	% Angular vs. time
	figure;
	hold('on');
	plot(t, rad2deg(p));
	plot(t, rad2deg(q));
	plot(t, rad2deg(r));
	grid('on');
	xlim([0 inf]);
	xlabel('Time [s]');
	ylabel('Angular Velocity [$^\circ$/s]');
	legend('$p$', '$q$', '$r$');

	% Set options
	set(findobj('Type', 'Legend'), 'Interpreter', 'latex');
	set(findobj('Type', 'axes'), 'FontSize', 12, 'TickLabelInterpreter', 'latex');
	set(findobj('Type', 'ColorBar'), 'TickLabelInterpreter', 'latex');
	set(findobj('Type', 'figure'), 'PaperUnits', 'centimeters', 'PaperPosition', [0 0 16 10]);
	set(findall(findobj('Type', 'axes'), 'Type', 'Text'), 'Interpreter', 'latex');
	set(findall(findobj('Type', 'axes'), 'Type', 'Line'), 'LineWidth', 1);
end

function [ph, th, ps, Lvb] = quaternion2euler(q0, q1, q2, q3, lat, lon, Lie)
	% Common
	N = numel(q0);
	i1 = 1:3:(1+(N-1)*3);
	i2 = 2:3:(2+(N-1)*3);
	i3 = 3:3:(3+(N-1)*3);
	i = [i1, i1, i1, i2, i2, i2, i3, i3, i3];
	j = [i1, i2, i3, i1, i2, i3, i1, i2, i3];

	% [EV] = V -> E
	k = [cos(lon)   ;  sin(lat).*sin(lon); -cos(lat).*sin(lon) ;
	     zeros(N, 1);  cos(lat)          ;  sin(lat)           ;
	     sin(lon)   ; -sin(lat).*cos(lon);  cos(lat).*cos(lon)];
	Lve = sparse(i, j, k);

	% [BI] = I -> B
	k = [q0.^2+q1.^2-q2.^2-q3.^2; 2*(q1.*q2+q0.*q3)      ; 2*(q1.*q3-q0.*q2)       ;
	     2*(q1.*q2-q0.*q3)      ; q0.^2-q1.^2+q2.^2-q3.^2; 2*(q0.*q1+q2.*q3)       ;
	     2*(q0.*q2+q1.*q3)      ; 2*(q2.*q3-q0.*q1)      ; q0.^2-q1.^2-q2.^2+q3.^2];
	Lib = sparse(i, j, k);

	% [IE] = E -> I
	Lei = Lie.';

	% [BV] = V -> B
	% [BV] = [BI][IE][EV]
	Lvb = Lib * Lei * Lve;
	Lvb(abs(Lvb) < 1e-12) = 0;

	% DCM -> Euler
	sz = size(Lvb);
	ph = atan2(Lvb(sub2ind(sz, i2, i3)), Lvb(sub2ind(sz, i3, i3)));
	th = -asin(Lvb(sub2ind(sz, i1,i3)));
	ps = atan2(Lvb(sub2ind(sz, i1, i2)), Lvb(sub2ind(sz, i1, i1)));

	% Full vectors
	ph = fixeuler(full(ph.'));
	th = fixeuler(full(th.'));
	ps = fixeuler(full(ps.'));

	function eu = fixeuler(eu)
		idx = find(abs(diff(eu)) > pi);
		if mod(numel(idx), 2)
			idx = [idx; numel(eu) - 1];
		end
		for l = 1:2:numel(idx)
			eu(1 + idx(l):idx(l+1)) = -sign(eu(idx(l)+1)) * 2*pi + eu(1 + idx(l):idx(l+1));
		end
	end
end
