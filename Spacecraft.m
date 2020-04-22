classdef Spacecraft < handle
	properties
		m; % mass [kg]
		L; % characteristic length [m]
		S; % reference surface area [m^2]
		I; % inertia matrix [kg.m^2]
		db; % struct with aerodynamic coefficients
	end

	methods
		% Constructor
		function self = Spacecraft(m, L, I, file)
			self.m = m;
			self.L = L;
			self.S = pi * self.L^2 / 4;
			self.I = diag(I);

			% Store database as struct
			self.db = load(file);
		end

		% Aerodynamic coefficients interpolant
		function Cx = Cx(self, str, alpha, Kn)
			Cx = interp2(self.db.Kn, self.db.alpha, self.db.(str), Kn, alpha);
		end
	end
end
