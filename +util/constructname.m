function filename = constructname(prefix, names)
	% util.constructname(names)
	% Identifies non-empty names and joins them with a prefix using a common format

	% Remove empty elements from cell array
	finalnames = names(~cellfun(@isempty, names));

	% Join non-empty names with '_'
	filename = [prefix strrep(char(~isempty(finalnames) * '_'), char(0), '') char(join(finalnames, '_'))];
end
