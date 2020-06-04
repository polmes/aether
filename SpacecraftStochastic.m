classdef SpacecraftStochastic < Spacecraft
	properties
		Cn = {'CL', 'CD', 'Cm'}; % Cx's names
		mean;
	end

	methods
		% Constructor
		function self = SpacecraftStochastic(m, L, R, I, file, alt, inputs)
			self = self@Spacecraft(m, L, R, I, file, alt);

			% Save mean values and variances
			for i = 1:numel(inputs)
				self.mean.(self.Cn{i}) = self.db.(self.Cn{i});
			end
		end

		function update(self, Y)
			% Add random noise to 3 Cx's: CL, CD, Cm
			for i = 1:numel(Y)
				self.db.(self.Cn{i}) = self.mean.(self.Cn{i}) * Y(i);
			end
		end
	end
end
