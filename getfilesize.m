function fileSize = getfilesize(fileName)
% GETFILESIZE returns the size of a file

% checks the number of arguments
error(nargchk(1, 1, nargin))

% checks the filename is a string
if ~ischar(fileName) || size(fileName, 1) ~= 1
    % errors
    error('Filename must be a string.')
end

% gets info on the file
dirStruct = dir(fileName);

% providing its not empty... (quicker than testing if the file exists)
if ~isempty(dirStruct)
    % return the file size
    fileSize = dirStruct.bytes;
    
else
    % errors since the file does not exist
    error('File does not appear to exist.')
end