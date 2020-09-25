function exception(msg, varargin)
	% Get call stack
	db = dbstack('-completenames');
	st = db(end);

	% Cases considered:
	%   Method of class in main directory -> aether:Class:method
	%   Method of class in package -> aether:package:Class:method
	%   Function in main directory -> aether:function
	%   Function in package -> aether:package:function

	% Try and find package name
	filedir = fileparts(st.file);
	relpath = filedir((numel(pwd) + 2):end);
	if ~isempty(relpath)
		relpath = strrep(relpath, filesep, ':');
		relpath = strrep(relpath, '+', '');
	end

	% Complete error ID
	id = ['aether:' relpath strrep(st.name, '.', ':')];

	ME = MException(id, msg, varargin{:});
	throwAsCaller(ME);
end
