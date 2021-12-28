% Munk profile test cases
% mbp
global units
units = 'km';

%%
current = pwd;
dirpath = dir('time*');
for id = 1: length(dirpath)
    name = dirpath(id).name;
    
    time = string(strsplit(name,'_'));
    it   = time(2);
    disp(it)
    newpath = strcat(current,'/',name);
    cd(name);
%     pwd
    eigen = char(strcat('Buoy-Ship_time',it,'_eigen'));
    amp   = char(strcat('Buoy-Ship_time',it,'_amp'));
    disp('==============bellhop eigen')
    bellhop(eigen)
    figure
    plotray(eigen)
    disp('==============bellhop amplitude')
    bellhop(amp)
    disp('==============delayandsum arr')
    arr   = char(strcat('Buoy-Ship_time',it,'_amp.arr'));
    delayandsum(arr)
    cd(current)
end

% figure
% plotssp( 'Buoy-Ship_time001_eigen' )
% 
% bellhop( 'Buoy-Ship_time001_eigen' )
% figure
% plotray( 'Buoy-Ship_time001_eigen' )

% bellhop( 'Buoy-Ship_time001_amp' )




