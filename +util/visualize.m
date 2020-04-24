function visualize(t, S, pl)
	%% TRAJECTORY

	rad = S(:,1); lat = S(:,2); lon = S(:,3);
	alt = rad - pl.R;
	x = rad .* cos(lat) .* cos(lon);
	y = rad .* cos(lat) .* sin(lon);
	z = rad .* sin(lat);

	figure;
	hold('on');
	plot3(x, y, z);

	if nargin > 2
		[xe, ye, ze] = sphere();
		xe = pl.R * xe;
		ye = pl.R * ye;
		ze = pl.R * ze;

		surf(xe, ye, ze);
	else
		plot3(0, 0, 0, 'k*');
	end

	axis('equal');
	xlabel('X');
	ylabel('Y');
	zlabel('Z');

	figure;
	hold('on');
	yyaxis('left');
	plot(t, alt / 1e3); % [km]
	yyaxis('right');
	plot(t, rad2deg(lat));
	plot(t, rad2deg(lon));

	%% ATTITUDE

	% Euler Angles
	q0 = S(:,4); q1 = S(:,5); q2 = S(:,6); q3 = S(:,7);
	ph = atan2(2 * (q0.*q1 + q2.*q3), 1 - 2 * (q1.^2 + q2.^2));
	th = asin(2 * (q0.*q2 - q3.*q1));
	ps = atan2(2 * (q0.*q3 + q1.*q2), 1 - 2 * (q2.^2 + q3.^2));

	figure;
	hold('on');
	plot(t, rad2deg(ph));
	plot(t, rad2deg(th));
	plot(t, rad2deg(ps));

	% Velocity
	u = S(:,8); v = S(:,9); w = S(:,10);
	Uinf = sqrt(sum(S(:,8:10).^2, 2));
	figure;
	hold('on');
	plot(t, u);
	plot(t, v);
	plot(t, w);
	plot(t, Uinf);

	% Angular velocity
	p = S(:,11); q = S(:,12); r = S(:,13);
	figure;
	hold('on');
	plot(t, p);
	plot(t, q);
	plot(t, r);
	
	% More angles
	alpha = atan2(S(:,10), S(:,8));
	gamma = alpha - th;
	figure;
	hold('on');
	plot(t, rad2deg(alpha));
	plot(t, rad2deg(th));
	plot(t, rad2deg(gamma));
	
	% Combined
	figure;
	plot(Uinf, alt);
end
