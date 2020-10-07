classdef Planet < matlab.mixin.Copyable
	% Planet
	% Base class to define properties of celestial bodies

	properties
		mu; % standard gravitational parameter [m^3/s^2]
		atm; % atmospheric model [Atmosphere]
		ellipsoid; % reference ellipsoid object
	end

	properties (Constant)
		G = 6.67430e-11; % universal gravitational constant [m^3/(kg.s^2)]
	end

	methods
		% Constructor
		function self = Planet(data)
			if nargin
				% Note: data *will* have the following properties since they are taken from defaults if not provided
				self.mu = self.G * data.M;
				self.atm = data.atm;
			end
		end

		% Range computation
		function ran = greatcircle(self, ~, lat1, lon1, ~, lat2, lon2)
			ran = distance(lat1, lon1, lat2, lon2, self.ellipsoid, 'radians');
		end
	end

	methods (Abstract)
		[lat, lon, alt, rad, Lie] = xyz2lla(self, x, y, z, t);
		[x, y, z, Lei] = lla2xyz(self, lat, lon, alt);
		g = gravity(self, rad, lat, lon, alt);
		vel = atmspeed(self, rad, lat);
	end
end
