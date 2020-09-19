classdef SpacecraftStochastic < Spacecraft
	properties
		Cn = {'CL', 'CD', 'Cm'}; % Cx's names
		mean;
	end

	methods
		% Constructor
		function self = SpacecraftStochastic(sc, inputs)
			% sc    :=  Spacecraft object (non-Stochastic)
			self = self.copy(sc); % @Spacecraft(sc);

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

	methods (Access = protected)
		function self = copy(self, obj)
			for pr = metaclass(self).PropertyList.'
				if isprop(obj, pr.Name) && ismember(pr.SetAccess, {'public', 'protected'})
					self.(pr.Name) = obj.(pr.Name);
				end
			end
		end
	end
end
