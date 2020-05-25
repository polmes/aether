classdef Random < matlab.mixin.Heterogeneous
	methods (Abstract)
		[x, w] = quadrature(self, m);
		x = adjust(self, x);
		x = random(self, n);
		p = partition(self, NS);
	end
end
