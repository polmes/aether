function QoI = getQoI(t, S, ie, sc, pl)
	% Constants
	%    Umag [m/s], f
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

	% Pre (assumes XYZ engine)
	x = S(:,1); y = S(:,2); z = S(:,3);
	[lat, lon, alt] = pl.xyz2lla(x, y, z, t);
	Umag = sqrt(sum(S(:,8:10).^2, 2));
	rho = pl.atm.trajectory(t, alt, lat, lon);

	% Status
	st = ie;

	% Time elapsed
	dur = t(end);

	% Range
	ran = pl.greatcircle(lat(1), lon(1), lat(end), lon(end));

	% Final velocity
	Uend = Umag(end);

	% Max speed
	maxU = max(Umag);

	% Max-g
	% maxG = max(sqrt(sum((diff(S(:,8:10)) ./ diff(t)).^2, 2)));
	maxG = max(abs(diff(Umag) ./ diff(t)));

	% Max-Q
	maxQ = max(1/2 * rho .* Umag.^2);

	% Convective heat flux
	dqc = Cc * sqrt(rho / sc.R) .* Umag.^3;

	% Radiative heat flux
	a = 1.072e6 * Umag.^(-1.88) .* rho.^(-0.325);
	dqr = Cr * sc.R.^a .* rho.^(1.22) .* interp1(f(:,1), f(:,2), Umag);
	dqr(a > 1) = 0; % out-of-range

	% Integrated heat
	dq = dqc + dqr;
	q = trapz(t, dq);

	QoI = [st, dur, ran, Uend, maxU, maxG, maxQ, q];
end
