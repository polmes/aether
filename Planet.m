classdef Planet < handle
	% Planet
	% Base class to define properties of celestial bodies

	properties
		R; % radius [m]
		% M; % mass [kg]
		mu; % standard gravitational parameter [m^3/s^2]
		% omega; % angular velocity [rad/s]
		atm; % atmospheric model [Atmosphere]
	end

	properties (Constant)
		G = 6.67430e-11; % universal gravitational constant [m^3/(kg.s^2)]
	end

	methods
		% Constructor
		function this = Planet(R, M, atm) % and T (period)
			% M = planet mass [kg]
			% T = rotation period [s]

			this.R = R;
			this.mu = M * this.G;
			% this.omega = 2*pi / T;
			this.atm = atm;
		end
	end
end
