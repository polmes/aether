function post(t, S, pl, sc)
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
	Uinf = sqrt(sum(S(:,8:10).^2, 2));
	rho = pl.atm.model(S(:,1) - pl.R);

	% Convective heat flux
	dqc = Cc * sqrt(rho / sc.R) .* Uinf.^3;

	% Radiative heat flux
	a = 1.072e6 * Uinf.^(-1.88) .* rho.^(-0.325);
	dqr = Cr * sc.R.^a .* rho.^(1.22) .* interp1(f(:,1), f(:,2), Uinf);
	idx = find(a < 1);
	dqrmod = zeros(size(t));
	dqrmod(idx) = dqr(idx);

	% Integrated heat
	dq = dqc + dqrmod;
	q = trapz(t, dq);
	disp(['Total Heat = ' num2str(q, '%.4e') ' J/m^2']);
	
	% Plot dq's
	figure;
	hold('on');
	plot(t, dqc);
	plot(t, dqrmod);
	plot(t, dq);
end
