classdef EngineRLStochastic < EngineRL
	properties (Access = protected, Constant)
		% Random inputs
		inputs = [uq.RandomGaussian(1, 0.05, true) , ... % for CL
		          uq.RandomGaussian(1, 0.05, true) , ... % for CD
		          uq.RandomGaussian(1, 0.05, true)];     % for Cm
	end

	methods
		function initial(self, S0, sc, pl, targetreward)
			initial@EngineRL(self, S0, sc, pl, targetreward);
			self.sc = SpacecraftStochastic(sc, self.inputs);
		end

		function observation = reset(self)
			observation = reset@EngineRL(self);

			Y = uq.MC(self.inputs, 1);
			self.sc.update(Y);
		end
	end
end
