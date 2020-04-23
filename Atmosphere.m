classdef Atmosphere < handle
	% Atmosphere
	% Base class for atmospheric models

	properties (Constant)
		% Universal Gas Constant
		Ru = 8.31446261815324; % [J/(mol.K)]

		% Avogadro's Number
		NA = 6.02214076e23; % [particles/mol]

		% Atmosphere (edge) limit
		lim = 120e3; % [m]
	end

	methods (Abstract)
		[rho, P, T] = model(self, h)
	end
end
