classdef PlanetSpherical < Planet
	% PlanetSpherical

	properties
		R; % radius [m]
	end

	methods
		% Constructor
		function self = PlanetSpherical(data)
			% Call superclass constructor
			self@Planet(data);

			% Additional properties
			self.R = data.R;

			% Construct sphere object
			self.ellipsoid = referenceSphere;
			self.ellipsoid.Radius = self.R;
		end

		% ECEF -> LLA
		function [lat, lon, alt, rad] = xyz2lla(self, x, y, z, ~)
			rad = sqrt(sum([x, y, z].^2, 2));
			lat = asin(y ./ rad);
			lon = asin(x ./ (rad .* cos(lat)));
			alt = rad - self.R;
		end

		% ECEF -> LLA
		function [lat, lon, alt, rad] = X2lla(self, X, ~)
			rad = norm(X);
			lat = asin(X(2) ./ rad);
			lon = asin(X(1) ./ (rad .* cos(lat)));
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
	end
end
