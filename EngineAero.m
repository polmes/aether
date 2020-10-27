classdef EngineAero < Engine
	properties (Access = protected)
		% New state scalars
		Uinf = 0;
		dAoA = 0;

		% New state vector
		Urel = zeros(3, 1);
	end

	methods (Access = protected)
		function dS = motion(self, t, S, sc, pl)
			% Call superclass method
			[dS, dU] = motion@Engine(self, t, S, sc, pl);

			% Keep track of angle of attack rate
			self.dAoA = (self.Urel(1) * dot(self.Urel, dU) - dU(1) * self.Uinf^2) / (self.Uinf^2 * sqrt(sum(self.Urel(2:3).^2)));
		end

		function [Fa, Ma] = aerodynamics(self, t, sc, pl)
			% Environment + Relative Velocity
			[rho, MFP, a, W] = pl.atm.trajectory(t, self.alt, self.lat, self.lon);
			self.Urel = self.U - self.Lvb * ([pl.atmspeed(self.rad, self.lat); 0; 0] + W);
			self.Uinf = norm(self.Urel);
			qS = 1/2 * rho * self.Uinf^2 * sc.S; % dynamic pressure * reference area

			% Angle of Attack
			totalAoA = acos(self.Urel(1) / self.Uinf);
			clockAoA = atan2(self.Urel(2), self.Urel(3));

			% Wind Axes Rotation
			Lwb = [cos(totalAoA)              ,  0            , -sin(totalAoA)               ;
			       sin(clockAoA)*sin(totalAoA),  cos(clockAoA),  sin(clockAoA)*cos(totalAoA) ;
			       cos(clockAoA)*sin(totalAoA), -sin(clockAoA),  cos(clockAoA)*cos(totalAoA)];
			Lbw = Lwb.';

			% Dimensionless numbers
			Kn = MFP / sc.L;
			M = self.Uinf / a;

			% Aerodynamic force coefficients
			CL = sc.Cx('CL', totalAoA, M, Kn);
			CD = sc.Cx('CD', totalAoA, M, Kn);

			% Forces
			FL = qS * CL;
			FD = qS * CD;
			FC = 0;
			Fa = Lwb * -[FD; FC; FL];

			% Aerodynamic moment coefficients
			Ww = Lbw * self.W;
			CmAft = sc.Cx('CmAft', totalAoA, M, Kn); % static stability
			Cmq = sc.Cx('Cmq', totalAoA, M, Kn) * (Ww(2) + self.dAoA) * sc.L / (2 * self.Uinf); % dynamic stability

			% Moments
			Ma = qS * sc.L * (CmAft + Cmq) * Lwb * [0; 1; 0] + cross(sc.CG, Fa); % note: CG in spacecraft object is already aft-CG
		end
	end
end
