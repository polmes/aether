function QoI = getQoI(t, S, ie, sc, pl)
	% Constants
	%    Uinf [m/s], f
	f = [0         , 0    ;
	     8999      , 0    ;
	     9000      , 1.5  ;
	     9250      , 4.3  ;
	     9500      , 9.7  ;
	     9750      , 19.5 ;
	     10000     , 35   ;
	     10250     , 55   ;
	     10500     , 81   ;
	     10750     , 115  ;
	     11000     , 151  ;
	     11500     , 238  ;
	     12000     , 359  ;
	     12500     , 495  ;
	     13000     , 660  ;
	     13500     , 850  ;
	     14000     , 1065 ;
	     14500     , 1313 ;
	     15000     , 1550 ;
	     15500     , 1780 ;
	     16000     , 2040];
	Cc = 18.8e-5; % convective heating constant [W/m^2]
	Cr = 4.736e8; % radiative heating constant [W/m^2]

	% Extract variables
	x = S(:,1); y = S(:,2); z = S(:,3);
	q0 = S(:,4); q1 = S(:,5); q2 = S(:,6); q3 = S(:,7);
	u = S(:,8); v = S(:,9); w = S(:,10);
	N = numel(t);

	% Pre-processing (assumes XYZ engine)
	[lat, lon, alt, rad, Lie] = pl.xyz2lla(x, y, z, t);
	rho = pl.atm.trajectory(t, alt, lat, lon);

	% Common
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

	% Velocities
	Urel = reshape([u, v, w].', [], 1) - Lvb * reshape(cat(2, pl.atmspeed(rad, lat), zeros(N, 1), zeros(N, 1)).', [], 1);
	Umag = sqrt(sum([u, v, w].^2, 2)); % inertial
	Uinf = sqrt(sum(reshape(Urel.^2, 3, []))).'; % freestream

	% Status
	st = ie(end);

	% Time elapsed
	dur = interp2deploy(alt, t, sc);

	% Range
	latf = interp2deploy(alt, lat, sc);
	lonf = interp2deploy(alt, lon, sc);
	ran = pl.greatcircle(rad(1), lat(1), lon(1), interp2deploy(alt, rad, sc), latf, lonf);

	% Final velocity (relative)
	Uend = interp2deploy(alt, Uinf, sc);

	% Max speed (inertial)
	maxU = max(Umag);

	% Max-g
	g0 = pl.gravity(rad(N), lat(N), lon(N), alt(N));
	maxG = max(abs(diff(Umag(1:N-1)) ./ diff(t(1:N-1)))) / g0;

	% Max-Q
	maxQ = max(1/2 * rho .* Uinf.^2);

	% Convective heat flux
	dqc = Cc * sqrt(rho / sc.R) .* Uinf.^3;

	% Radiative heat flux
	a = 1.072e6 * Uinf.^(-1.88) .* rho.^(-0.325);
	dqr = Cr * sc.R.^a .* rho.^(1.22) .* interp1(f(:,1), f(:,2), Uinf);
	dqr(a > 1) = 0; % out-otf-range

	% Max heat flux
	dq = dqc + dqr;
	maxdq = max(dq);

	% Integrated heat
	q = trapz(t, dq);

	QoI = [st, dur, ran, Uend, latf, lonf, maxU, maxG, maxQ, maxdq, q];

	function yq = interp2deploy(alt, q, sc)
		[x, idx] = unique(alt);
		y = q(idx);
		yq = interp1(x, y, sc.deploy, 'linear', 'extrap');
	end
end
