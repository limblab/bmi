function traj = curs_traj_default

%find path of the default trajectory file
% file is 'default_cursor_traj_R10.mat'
% it is in the /bmi/backpropagation folder

filename = 'default_cursor_traj_R10.mat';

p = path;
pathsep = strfind(p,':');
idx = strfind(p,['bmi' filesep 'backpropagation']);
idx = find(pathsep<idx,1,'last');

filepath = p((pathsep(idx)+1):(pathsep(idx+1)-1));

traj = load(fullfile(filepath,filename));
