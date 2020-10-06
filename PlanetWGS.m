classdef PlanetWGS < PlanetRotating
	% PlanetWGS
	% WGS-84 geoid planetary model
	% Note: lat in Engine *will* be GEOCENTRIC (for GRAM compatibility)

	methods
		% Constructor
		function self = PlanetWGS(data)
			% Call superclass constructor
			self@PlanetRotating(data);

			% Construct ellipsoid object
			self.ellipsoid = wgs84Ellipsoid;
		end

		function [lat, lon, alt, rad] = xyz2lla(self, x, y, z, t)
			% ECI -> ECEF
			[xe, ye, ze] = self.xyz2ecef(x, y, z, t);
			rad = sqrt(sum([xe, ye, ze].^2, 2));

			% ECEF -> LLA
			lla = ecef2lla([-ze, xe, -ye]); % nominal ECEF
			alt = lla(:,3); % [m]
			lon = deg2rad(lla(:,2)); % [deg] -> [rad]
			lat = deg2rad(geod2geoc(lla(:,1), alt)); % geodetic -> geocentric + [deg] -> [rad]
		end

		function [x, y, z, Lei] = lla2xyz(self, lat, lon, alt)
			% LLA -> ECEF
			Xe = lla2ecef([geoc2geod(rad2deg(lat), alt), rad2deg(lon), alt]);

			% ECEF -> ECI
			[x, y, z, Lei] = self.ecef2xyz(Xe(:,2), -Xe(:,3), -Xe(:,1)); % my ECEF sign convention
		end

		% WGS-84 Gravity Field
		function g = gravity(~, rad, lat, lon, alt)
			g = gravitywgs84(alt, geoc2geod(rad2deg(lat), rad), rad2deg(lon), 'Exact');
		end

		% Range computation geodetic override
		function ran = greatcircle(self, rad1, lat1, lon1, rad2, lat2, lon2)
			ran = distance(geoc2geod(rad2deg(lat1), rad1), rad2deg(lon1), geoc2geod(rad2deg(lat2), rad2), rad2deg(lon2), self.ellipsoid);
		end
	end
end
