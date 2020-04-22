classdef Atmosphere < handle
	% Atmosphere
	% Base class for atmospheric models

	properties (Constant)
		% Universal Gas Constant
		Ru = 8.31446261815324; % [J/(mol.K)]

		% Atmosphere (edge) limit
		lim = 120e3; % [m]
	end

	methods (Abstract)
		[P, T, rho] = model(this, h)
	end
end
