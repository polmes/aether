classdef PlanetSphericalRotating < PlanetSpherical & PlanetRotating
	% PlanetSphericalRotating

	methods
		% Constructor
		function self = PlanetSphericalRotating(data)
			% Call superclass constructors
			self@PlanetSpherical(data);
			self@PlanetRotating(data);
		end

		function [lat, lon, alt, rad, Lie] = xyz2lla(self, x, y, z, t)
			% ECI -> ECEF
			[xe, ye, ze, Lie] = self.xyz2ecef(x, y, z, t);

			% ECEF -> LLA
			[lat, lon, alt, rad] = xyz2lla@PlanetSpherical(self, xe, ye, ze, t);
		end

		function [lat, lon, alt] = X2lla(self, X, t)
			% ECI -> ECEF
			Xe = self.X2ecef(X, t);

			% ECEF -> LLA
			[lat, lon, alt] = X2lla@PlanetSpherical(self, Xe, t);
		end

		function [x, y, z, Lei] = lla2xyz(self, lat, lon, alt)
			% LLA -> ECEF
			[xe, ye, ze] = lla2xyz@PlanetSpherical(self, lat, lon, alt);

			% ECEF -> ECI
			[x, y, z, Lei] = self.ecef2xyz(xe, ye, ze);
		end
	end
end
