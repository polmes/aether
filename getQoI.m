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

	% Pre
	alt = S(:,1) - pl.R;
	Uinf = sqrt(sum(S(:,8:10).^2, 2));
	rho = pl.atm.model(alt);

	% Status
	st = ie;

	% Time elapsed
	dur = t(end);

	% Final position
	pos = S(end,2);

	% Final velocity
	Uend = Uinf(end);

	% Max speed
	maxU = max(Uinf);

	% Max-g
% 	maxG = max(sqrt(sum((diff(S(:,8:10)) ./ diff(t)).^2, 2)));
	maxG = max(abs(diff(Uinf) ./ diff(t)));

	% Max-Q
	maxQ = max(1/2 * rho .* Uinf.^2);

	% Convective heat flux
	dqc = Cc * sqrt(rho / sc.R) .* Uinf.^3;

	% Radiative heat flux
	a = 1.072e6 * Uinf.^(-1.88) .* rho.^(-0.325);
	dqr = Cr * sc.R.^a .* rho.^(1.22) .* interp1(f(:,1), f(:,2), Uinf);
	dqr(a > 1) = 0; % out-of-range

	% Integrated heat
	dq = dqc + dqr;
	q = trapz(t, dq);

	QoI = [st, dur, pos, Uend, maxU, maxG, maxQ, q];
end
