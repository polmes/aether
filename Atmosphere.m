classdef Atmosphere < handle
	% Atmosphere
	% Base class for atmospheric models

	properties (Constant)
		% Atmosphere (edge) limit = Entry Interface (EI)
		lim = 121.92e3; % [m] = 400k ft
	end

	properties (Access = protected, Constant)
		% Universal Gas Constant
		Ru = 8.31446261815324; % [J/(mol.K)]

		% Avogadro's Number
		NA = 6.02214076e23; % [particles/mol]

		% Default wind velocity
		W = zeros(3, 1);
	end

	methods (Abstract)
		% Standard method to get atmospheric properties during trajectory propgation
		[rho, MFP, a, W] = trajectory(self, t, alt, lat, lon);
	end
end
