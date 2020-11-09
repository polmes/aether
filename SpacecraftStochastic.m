classdef SpacecraftStochastic < Spacecraft
	properties
		Cn; % Cx's names
		mean;
	end

	properties (Access = protected)
		idx;
	end

	properties (Access = protected, Constant)
		sorted = {'CL', 'CD', {'Cm', 'CmAft'}, 'Cmq'}; % possible coefficient names in order of priority
	end

	methods
		% Constructor
		function self = SpacecraftStochastic(sc, inputs, Ms, Kns)
			% sc    :=  Spacecraft object (non-Stochastic)
			self = self.copy(sc); % @Spacecraft(sc);

			% Get available coefficients
			allCn = fieldnames(self.db);
			self.Cn = cell(1, numel(inputs));

			if nargin == 2
				self.idx = find(self.db.alpha);
			elseif nargin == 4
				self.idx = find((self.db.M >= Ms(1) & self.db.M <= Ms(2)) & (self.db.Kn >= Kns(1) & self.db.Kn <= Kns(2)));
			else
				util.exception('Expected either 2 or 4 input arguments');
			end

			% Save coefficient names and their mean values
			for i = 1:numel(inputs)
				self.Cn{i} = cell2mat(intersect(self.sorted{i}, allCn));
				self.mean.(self.Cn{i}) = self.db.(self.Cn{i});
			end
		end

		function update(self, Y)
			% Add random noise to first N Cx's: CL, CD, Cm, ...
			% but only to the corresponding indices
			for i = 1:numel(Y)
				self.db.(self.Cn{i})(self.idx) = self.mean.(self.Cn{i})(self.idx) * Y(i);
				self.F.(self.Cn{i}) = griddedInterpolant(self.db.alpha, self.db.M, self.db.Kn, self.db.(self.Cn{i}));
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
