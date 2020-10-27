classdef PlanetSpherical < Planet
	% PlanetSpherical

	methods
		% Constructor
		function self = PlanetSpherical(data)
			% Call superclass constructor
			self@Planet(data);

			% Construct sphere object
			self.ellipsoid = referenceSphere;
			self.ellipsoid.Radius = self.R;
		end

		% ECEF -> LLA (vectorized)
		function [lat, lon, alt, rad, Lie] = xyz2lla(self, x, y, z, ~)
			rad = sqrt(sum([x, y, z].^2, 2));
			lat = asin(-y ./ rad);
			lon = atan2(x, -z);
			alt = rad - self.R;
			Lie = speye(3 * numel(x));
		end

		% ECEF -> LLA
		function [lat, lon, alt] = X2lla(self, X, ~)
			rad = norm(X);
			lat = asin(-X(2) ./ rad);
			lon = atan2(X(1), -X(3));
			alt = rad - self.R;
		end

		% LLA -> ECEF
		function [x, y, z, Lei] = lla2xyz(self, lat, lon, alt)
			rad = self.R + alt;
			x =  rad * cos(lat) * sin(lon);
			z = -rad * cos(lat) * cos(lon);
			y = -rad * sin(lat);
			Lei = eye(3);
		end

		% Standard Newtonian Gravity
		function g = gravity(self, rad, ~, ~, ~)
			g = self.mu ./ rad.^2;
		end

		% Fixed atmosphere in this case
		function vel = atmspeed(~, rad, ~)
			vel = zeros(numel(rad), 1);
		end
	end
end
