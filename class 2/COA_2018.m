clear
addpath('mfiles/');

load('matfiles/wd_ChaoJing_new.mat')
%%
load('matfiles/gps')
% gps.vr     [3x2400] relative velocity
%    .vrTime [1x2400] time vector
%    .dist
%      1: AUV and Buoy
%      2: AUV and Ship
%      3: Buoy and Ship
%    .lonMin (latMin)
%    AUV: 1 (station ID)
%   Buoy: 2
% Yellow: 3

% I suggest that you convert lat/lon vectors into UTM coordinates before
% doing any calculation
itime = 1
AUV_pos = [121+gps.lonMin(1,itime)./60  25+gps.latMin(1,itime)./60];
Ship_pos = [121+gps.lonMin(3,itime)./60  25+gps.latMin(3,itime)./60];
WD_new(AUV_pos) % water depth at the AUV_pos

% determine the water depth between stations

writebty(['ray_simu/' Path(ii).pname '.bty'],'C',[(Path(ii).range), Path(ii).dep])

envfil = 'AUV-Ship';
titleenv = ['ChaoJing (' envfil ')' ] ;
writeenv_ray(envfil, titleenv, freq, Nmedia, topopt, ...
  ocean_ssp, Nmesh, sigma, OPTIONS2,cpb, csb, rhob, attb, sd, Nrd, rd, Nrr,...
  rr, runtyp, Nbeams, alpha, step, zbox, rbox);

load('matfiles/Arr')
% Arr(1:6).arr   [121x3000]; magnitude of the arrival
%         .time  [121x3000]; time vector / unit(s) 
%         .freq  [1x121];    estimated Doppler frequency 
%			 .staIdRx;          Rx Station ID  #receiver 接收
%			 .staIdTx;          Tx Station ID  #transmission 發射
%			 .staNameRx;        Rx Station Name
%			 .staNameTx;        Tx Station Name
% There are 121 transmissions; for each transmission 3000 samples are saved.
% Note: the starting time is 2017/6/27 15:45 with an interval of 20 sec.
%
% The indices of Arr from 1 to 6 indicate the transmission pairs:
%    1 & 3: between AUV and Buoy;
%    2 & 5: between AUV and Ship;
%    4 & 6: between Buoy and Ship.



