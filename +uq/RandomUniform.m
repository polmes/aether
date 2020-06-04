classdef RandomUniform < uq.Random
	properties
		a;
		b;
	end

	properties (Constant)
		rule = 'gauss-legendre'; % for TASMANIAN
	end

	methods
		function self = RandomUniform(a, b, perc)
			if nargin < 3 || isempty(perc)
				perc = false;
			end

			if ~perc
				% Direct limits
				self.a = a;
				self.b = b;
			else
				% Given percentage
				self.a = a - a * b;
				self.b = a + a * b;
			end
		end

		function [x, w] = quadrature(self, m)
			% Computes Legendre polynomial abscissas and weights
			% for Gauss quadrature
			%
			% Input arguments:
			%	m : Number of Gauss points, taking into account that
			%	    m points integrate exactly a polynomial of order
			%	    p <= 2m - 1
			%
			% Output arguments:
			%	x : Coordinates/abscissas in which to evaluate the function
			%	    to be integrated, [x1, x2, ..., xm]
			%	w : Weights of each Gauss point during the sum,
			%	    [w1, w2, ..., wm]

			n = 1:(m - 1);
			beta = n ./ sqrt(4 * n.^2 - 1);
			T = diag(beta, 1) + diag(beta, -1);
			[V, D] = eig(T);

			x = self.a + (self.b - self.a) / 2 * (diag(D) + 1); % abscissas
			w = (2 * V(1,:).^2).'; % weights
		end

		function x = adjust(self, x)
			x = self.a + (self.b - self.a) / 2 * (x + 1);
		end

		function x = random(self, n, m)
			if nargin < 3
				m = 1;
			end

			x = self.a + (self.b - self.a) * rand(n, m);
		end

		function p = partition(self, n)
			p = linspace(self.a, self.b, n + 1);
		end
	end
end
