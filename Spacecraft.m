classdef Spacecraft < handle
	properties
		m; % mass [kg]
		L; % characteristic length [m]
		R; % nose radius [m]
		S; % reference surface area [m^2]
		I; % inertia matrix [kg.m^2]
		db; % struct with aerodynamic coefficients
		deploy; % altitude at which to deploy drogue/parachutes
	end
	
	properties (Constant)
		datadir = 'mat/';
	end

	methods
		% Constructor
		function self = Spacecraft(m, L, R, I, file, alt)
			self.m = m;
			self.L = L;
			self.R = R;
			self.S = pi * self.L^2 / 4;
			self.I = diag(I);
			self.deploy = alt;

			% Store database as struct
			self.db = load([self.datadir file '.mat']);
		end

		% Aerodynamic coefficients interpolant
		function Cx = Cx(self, str, alpha, Kn)
			Cx = interp2(self.db.Kn, self.db.alpha, self.db.(str), Kn, alpha);
		end
	end
end
