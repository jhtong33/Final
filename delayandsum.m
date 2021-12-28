function delayandsum(arrfile)
% -------------------------------------------------------------------------
% delayandsum(arrfile)
%
% Description: Function to convert lat/lon vectors into UTM coordinates (WGS84).
% Some code has been extracted from UTM.m function by Gabriel Ruiz Martinez.
%
% Inputs:
%    arrfile: bellhop amplitude file .arr 
% plot replica time series
% mbp 8/96, Universidade do Algarve
% 4/09 addition of Doppler effects

% clear
load ceig
ColorOrderNew = colormap(jet(21));
ColorOrderNew = ColorOrderNew(1:2:20,:);

v  = [ 0, 0 ];   % Receiver motion vector (vr, vz ) in m/s
c0 = 1500;       % reference speed to convert v to proportional Doppler

ARRFIL = arrfile;

% source time series
signal = load('signal.mat');
sample_rate = signal.fs;
TT = signal.TT;
sts = signal.sts / max(abs(signal.sts));


% play with the narrower bandwidth by applying a low pass filter
[BB,AA] = butter(4,1000./(sample_rate/2),'low');
%figure; freqz(BB,AA,128,sample_rate);
sts1 = filtfilt(BB,AA,sts);
sts1 = sts1 / max( abs( sts1 ) );

% normalize the source time series so that it has 0 dB source level
% (measured based on the peak power in the timeseries)
figure(1);clf
subplot(211)
plot(TT*1000,sts,'b');hold on
xlim([-1 1])
% subplot(212)
% plot(TT*1000,sts1,'r') % lowpass filter 
% xlim([-1 1])
set(gca,'fontsize',14,'linewidth',1,'tickdir','out');
xlabel('Time (ms)');ylabel('Amp.')
nts = length(sts);
%%
% optional Doppler effects
% pre-calculate Dopplerized versions of the source time series

% following can be further optimized if we know that ray-angle limits
% further restrict possible Doppler factors

if ( norm( v ) > 0 )
  disp( 'Setting up Dopplerized waveforms' )
  v_vec = linspace( min( v ), max( v ), 10 );   % vector of Doppler velocity bins
  v_vec = linspace( 1.9, 2, 51 );   % vector of Doppler velocity bins
  alpha_vec   = 1 - v_vec / c0;                     % Doppler factors
  nalpha      = length( alpha_vec );
  sts_hilbert = zeros( nts, nalpha );
  % loop over Doppler factors (should be further vectorized ...)
  for ialpha = 1 : length( alpha_vec )
    disp( ialpha )
    sts_hilbert( :, ialpha ) = hilbert( arbitrary_alpha( sts', alpha_vec( ialpha ) )' ); % Dopplerize
  end
else
  sts_hilbert = hilbert( sts );   % need the Hilbert transform for phase changes (imag. part of amp)
end
figure(3);clf
subplot(221)
plot(TT*1000,real(sts_hilbert),'b');hold on
%plot(TT,sts1,'r')
set(gca,'ytick',[-1:0.25:1])
set(gca,'xtick',[-1:0.2:1])
xlim([-0.5 0.5])
ylim([-1 1])
set(gca,'fontsize',14,'linewidth',1,'tickdir','out');
title('s(t)')
xlabel('Time (ms)')
ylabel('Amp.')
grid on
subplot(222)
plot(TT*1000,imag(sts_hilbert),'b');hold on
%plot(TT,sts1,'r')
xlim([-0.5 0.5])
ylim([-1 1])
grid on
set(gca,'ytick',[-1:0.25:1])
set(gca,'xtick',[-1:0.2:1])
set(gca,'fontsize',14,'linewidth',1,'tickdir','out');
title('s(t)')
xlabel('Time (ms)')
ylabel('Amp.')
grid on
print -dpdf source
%%

%**************************************************************************

c = 1533.0;  % reduction velocity (should exceed fastest possible arrival)
T = 0.2;     % time window to capture

[ Arr, Pos ] = read_arrivals_asc( ARRFIL);  % read the arrivals file
disp( 'Done reading arrivals' )

% select which source/receiver index to use
ir  = length( Pos.r.r );
isd = length( Pos.s.z);

deltat = 1 / sample_rate;
nt     = round( T / deltat );	% number of time points in rts
rtsmat = zeros( nt, length( Pos.r.r ) );

for ird = 1 : length( Pos.r.z );
  for ir = 1 : length( Pos.r.r )   % loop over receiver ranges
    disp( [ ird, ir ] )
    
    % define time vector
    tstart = Pos.r.r( ir ) / c + (min(TT));   % min( delay( ir, :, ird ) )
    tend   = tstart + T - deltat;
    time   = tstart : deltat : tend;
    
    % compute channel transfer function
    
    rts = zeros( nt, 1 );	% initialize the time series
    % C_eig(kk)
    ij = 0;
    for iarr = 1:10;%Arr.Narr( ir, ird, isd ) % C_eig
      ij = ij+1;
      %1 : Arr.Narr( ir, ird, isd )   % loop over arrivals
      
      Tarr = Arr.delay( ir, iarr, ird, isd ) - tstart + min(TT);   % arrival time relative to tstart
      arruser_time(ij) =  Arr.delay( ir, iarr, ird, isd ); % CFH
      it1  = round( Tarr / deltat + 1 );             % starting time index in rts for that delay
      it2  = it1 + nts - 1;                          % ending   time index in rts
      its1 = 1;                                      % starting time index in sts
      its2 = nts;                                    % ending   time index in sts
      
      % clip to make sure [ it1, it2 ] is inside the limits of rts
      if ( it1 < 1 )
        its1 = its1 + ( 1 - it1 );  % shift right by 1 - it1 samples
        it1  = 1;
      end
      
      if ( it2 > nt )
        its2 = its2 - ( it2 - nt );  % shift left by it2 - nt samples
        it2  = nt;
      end
      
      if ( norm( v ) > 0 )
        
        % identify the Doppler bin
        theta_ray = Arr.RcvrAngle( ir, iarr, ird ) * pi / 180;    % convert ray angle to radians
        tan_ray   = [ cos( theta_ray ) sin( theta_ray ) ];        % form unit tangent
        alpha     = 1 - dot( v / c0, tan_ray );                   % project Doppler vector onto ray tangent
        ialpha    = 1 + round( ( alpha - alpha_vec( 1 ) ) / ( alpha_vec( end ) - alpha_vec( 1 ) ) * ( length( alpha_vec ) - 1 ) );
        
        % check alpha index within bounds?
        if ( ialpha < 1 || ialpha > nalpha )
          disp( 'Doppler exceeds pre-tabulated values' )
          ialpha = max( ialpha, 1 );
          ialpha = min( ialpha, nalpha );
        end
        
        % load the weighted and Dopplerized waveform into the received time series
        rts( it1 : it2 ) = rts( it1 : it2 ) + real( Arr.A( ir, iarr, ird ) * sts_hilbert( its1 : its2, ialpha ) );
      else
        arruser_amp(ij) = Arr.A( ir, iarr, ird ); % CFH
        
        %  rts( it1 : it2 ) = rts( it1 : it2 ) + real( Arr.A( ir, iarr, ird ) ) * real( sts_hilbert( its1 : its2, 1 ) ) ...
        %                                      - imag( Arr.A( ir, iarr, ird ) ) * imag( sts_hilbert( its1 : its2, 1 ) );
        % following is math-equivalent to above, but runs faster in
        % Matlab even though it looks like more work ...
        rts( it1 : it2 ) = rts( it1 : it2 ) + real( Arr.A( ir, iarr, ird ) * sts_hilbert( its1 : its2, 1 ) );
        if 1 % plot each arrival
          figure(2)
          subplot(5,2,ij)
          plot(time( it1 : it2 )*1000,real( Arr.A( ir, iarr, ird ) ) * real( sts_hilbert( its1 : its2, 1 ) ) ,'r')
          hold on
          plot(time( it1 : it2 )*1000, - imag( Arr.A( ir, iarr, ird ) ) * imag( sts_hilbert( its1 : its2, 1 ) ),'b')
          plot(time( it1 : it2 )*1000,...
            real( Arr.A( ir, iarr, ird ) * sts_hilbert( its1 : its2, 1 ) ),'k')
%           xlim([1275 1290])
        end
        figure(1)
        subplot(212)
        plot(time( it1 : it2 )*1000,...
          real( Arr.A( ir, iarr, ird ) * sts_hilbert( its1 : its2, 1 ) ),...
          'color',ColorOrderNew(iarr,:))
        hold on
        stem(arruser_time(ij)*1000,abs(arruser_amp(ij)),'color',ColorOrderNew(iarr,:))
        hold on
%         xlim([1274 1286])
      end
    end   % next arrival, iarr
    
    rtsmat( :, ir ) = rts;
  end
  %eval( [ ' save ' ARRFIL(1:end-4) '_Rd_' num2str( ird ) ' rtsmat Pos sample_rate' ] );
end
%%
figure(1)
subplot(212)
%plot(time*1000,rtsmat)
%hold on
plot(time*1000,abs(hilbert(rtsmat)),'k')

xlabel('Time (ms)')
ylabel('Amp.')
set(gca,'fontsize',14,'linewidth',1,'tickdir','out');
set(gcf,'paperposition',[0.25 0.25 10.5 8])
print -dpng timeseries

datacolumns = {'time','envelop'};
datatable = table(transpose(time),abs(hilbert(rtsmat)),'VariableNames',datacolumns);
writetable(datatable,'envelop.csv','WriteVariableNames',true);
end
%save autec
%foo = reshape( rtsmat, 1, nt * length( Pos.r.range ) );

% figure; pcolor( Pos.r.range, linspace( 0, T, nt ), 20 * log10 ( abs( hilbert( rtsmat' ) ) ) ); shading flat; colorbar
% xlabel( 'Time (s)' )
% ylabel( 'Range (m)' )
