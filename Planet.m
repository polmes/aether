classdef Planet < matlab.mixin.Copyable
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
		function self = Planet(data) % and T (period)
			% M = planet mass [kg]
			% T = rotation period [s]
			if nargin
				% Note: data *will* have the following properties since they are taken from defaults if not provided
				self.R = data.R;
				self.mu = self.G * data.M;
				% self.omega = 2*pi / T;
				self.atm = data.atm;
			end
		end
	end
end
