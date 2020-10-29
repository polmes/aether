classdef EngineAeroDelta < Engine
	properties (Access = protected)
		% New state scalars
		dAoA = 0;
		delta = 0;
		alpha = 0;
		beta = 0;

		% New state vector
		Urel = zeros(3, 1);
	end

	methods (Static)
		function S0 = prepare(S, pl)
			% Call superclass method
			S0 = prepare@Engine(S(1:12), pl);

			% Append initial bank angle
			S0 = [S0; S(13)];
		end

		function NS = NS()
			NS = 14;
		end
	end

	methods (Access = protected)
		function dS = motion(self, t, S, sc, pl)
			% Call superclass method
			dS = motion@Engine(self, t, S, sc, pl);

			% Keep track of angle of attack rate
			Uinf = norm(self.Urel);
			self.dAoA = (self.Urel(1) * dot(self.Urel, self.dU) - self.dU(1) * Uinf^2) / (Uinf^2 * sqrt(sum(self.Urel(2:3).^2)));

			% Keep track of bank angle offset
			self.delta = S(14);

			% Append bank angle rate to state vector
			ddelta = self.W(1);
			dS = [dS; ddelta];
		end

		function [Fa, Ma] = aerodynamics(self, t, sc, pl)
			% Environment + Relative Velocity
			[rho, MFP, a, W] = pl.atm.trajectory(t, self.alt, self.lat, self.lon);
			self.Urel = self.U - self.Lvb * ([pl.atmspeed(self.rad, self.lat); 0; 0] + W);
			Uinf = norm(self.Urel);
			qS = 1/2 * rho * Uinf^2 * sc.S; % dynamic pressure * reference area

			% Nominal frame of reference
			Lbn = [1,  0              , 0               ;
			       0,  cos(self.delta), sin(self.delta) ;
			       0, -sin(self.delta), cos(self.delta)];
			Lnb = Lbn.';
			U = Lbn * self.Urel;

			% (Total) Angle of Attack
			Uyz = U(3) * sqrt((U(2) / U(3))^2 + 1);
			AoA = atan2(Uyz, U(1));
			self.alpha = atan2(U(3), U(1));
			self.beta = asin(U(2) / Uinf);

			% Wind Axes Rotation
			Lwn = [cos(self.alpha)*cos(self.beta), -cos(self.alpha)*sin(self.beta), -sin(self.alpha) ;
			       sin(self.beta)                ,  cos(self.beta)                ,  0               ;
			       sin(self.alpha)*cos(self.beta), -sin(self.alpha)*sin(self.beta),  cos(self.alpha)];
			Lnw = Lwn.';

			% Dimensionless numbers
			Kn = MFP / sc.L;
			M = Uinf / a;

			% Aerodynamic force coefficients
			CL = sc.Cx('CL', AoA, M, Kn);
			CD = sc.Cx('CD', AoA, M, Kn);

			% Forces (W -> N)
			FL = qS * CL;
			FD = qS * CD;
			FC = 0;
			Fa = Lwn * -[FD; FC; FL];

			% Aerodynamic moment coefficients
			Ww = Lnw * self.W;
			CmAft = sc.Cx('CmAft', AoA, M, Kn); % static stability
			Cmq = sc.Cx('Cmq', AoA, M, Kn) * (Ww(2) + self.dAoA) * sc.L / (2 * Uinf); % dynamic stability

			% Moments (N)
			rCG = Lnb * sc.CG; % note: CG in spacecraft object is already aft-CG
			Ma = qS * sc.L * (CmAft + Cmq) * [0; cos(self.beta); sin(self.beta)] + cross(rCG, Fa);

			% Vectors in body frame (N -> B)
			Fa = Lnb * Fa;
			Ma = Lnb * Ma;
		end
	end
end
