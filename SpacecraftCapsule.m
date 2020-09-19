classdef SpacecraftCapsule < Spacecraft
	methods
		function self = SpacecraftCapsule(data)
			self = self@Spacecraft(data);

			% In capsules, characteristic length = diameter
			% and, therefore, the reference area is:
			self.S = pi * self.L^2 / 4;
		end
	end
end
