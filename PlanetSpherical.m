classdef PlanetSpherical < Planet
	methods
		function self = PlanetSpherical(data)
			% Call superclass constructor
			self@Planet(data);

			% Construct sphere object
			self.ellipsoid = referenceSphere;
			self.ellipsoid.Radius = self.R;
		end
		function [lat, lon, alt] = xyz2lla(self, x, y, z)
			rad = sqrt(sum([x, y, z].^2, 2));
			lat = asin(y ./ rad);
			lon = asin(x ./ (rad .* cos(lat)));
			alt = rad - self.R;
		end

		function [x, y, z] = lla2xyz(self, lat, lon, alt)
			rad = self.R + alt;
			x =  rad * cos(lat) * sin(lon);
			z = -rad * cos(lat) * cos(lon);
			y = -rad * sin(lat);
		end

		function ran = greatcircle(self, lat1, lon1, lat2, lon2)
			ran = distance(lat1, lon1, lat2, lon2, self.ellipsoid, 'radians');
		end
	end
end
