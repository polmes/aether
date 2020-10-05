classdef EngineAero < Engine
	properties (Access = protected)
		% New property
		dAoA = 0;

		% New state scalar
		delta = 0;
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
			[dS, dU] = motion@Engine(self, t, S, sc, pl);

			% Keep track of dAoA
			Uinf = norm(self.U);
			self.dAoA = (self.U(1) * dot(self.U, dU) - dU(1) * Uinf^2) / (Uinf^2 * sqrt(sum(self.U(2:3).^2)));

			% Keep track of bank angle offset
			self.delta = S(14);

			% Append bank angle rate to state vector
			ddelta = self.W(1);
			dS = [dS; ddelta];
		end

		function [Fa, Ma] = aerodynamics(self, t, sc, pl)
			% % (Total) Angle of Attack
			% Uinf = norm(self.U);self
			% % AoA = acos(self.U(1) / Uinf);
			% alpha = atan2(self.U(3), self.U(1));
			% beta = asin(self.U(2) / Uinf);

			% % Total Angle of Attack
			% % Uinf = norm(self.U);
			% AoA = acos(self.U(1) / Uinf);
			% clockAoA = atan2(self.U(2), self.U(3));

			% Nominal frame of reference
			% Qn = [self.Q(1); self.Q(2) - self.q1n; 0; 0];
			% Qn = 1/norm(Qn) * Qn;
			% q0 = Qn(1); q1 = Qn(2); q2 = Qn(3); q3 = Qn(4);
			% Lnb = [q0^2+q1^2-q2^2-q3^2, 2*(q1*q2+q0*q3)    , 2*(q1*q3-q0*q2)     ;
			%        2*(q1*q2-q0*q3)    , q0^2-q1^2+q2^2-q3^2, 2*(q0*q1+q2*q3)     ;
			%        2*(q0*q2+q1*q3)    , 2*(q2*q3-q0*q1)    , q0^2-q1^2-q2^2+q3^2];
			Lbn = [1,                0,               0 ;
			       0,  cos(self.delta), sin(self.delta) ;
			       0, -sin(self.delta), cos(self.delta)];
			Lnb = Lbn.';
			% Lbn = Lnb.';
			U = Lbn * self.U;
			Uinf = norm(U);

			% (Total) Angle of Attack
			Uyz = U(3) * sqrt((U(2) / U(3))^2 + 1);
			AoA = atan2(Uyz, U(1));
			alpha = atan2(U(3), U(1));
			beta = asin(U(2) / Uinf);

			% Wind Axes Rotation
			Lwn = [cos(alpha)*cos(beta), -cos(alpha)*sin(beta), -sin(alpha) ;
			       sin(beta)           ,  cos(beta)           ,  0          ;
			       sin(alpha)*cos(beta), -sin(alpha)*sin(beta),  cos(alpha)];
			Lnw = Lwn.';

			% Environment
			[rho, MFP, a] = pl.atm.trajectory(t, self.alt, self.lat, self.lon);
			Kn = MFP / sc.L;
			M = Uinf / a;
			qS = 1/2 * rho * Uinf^2 * sc.S; % dynamic pressure * reference area

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
			Ma = qS * sc.L * (CmAft + Cmq) * [0; 1; 0] + cross(rCG, Fa);

			% Vectors in body frame (N -> B)
			Fa = Lnb * Fa;
			Ma = Lnb * Ma;
		end
	end
end
