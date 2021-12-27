% Uses the workspace variables to write out an envfil
function writeenv_ray(envfil, titleenv, freq, Nmedia, topopt, ...
    ocean_ssp, Nmesh, sigma, OPTIONS2,cpb, csb, rhob, attb, sd, Nrd, rd, Nrr,...
    rr, runtyp, Nbeams, alpha, step, zbox, rbox);
fid = fopen( [envfil '.env'], 'w' );

fprintf( fid, ' '' %s '' \r\n', titleenv );
fprintf( fid, '%f \r\n', freq );
fprintf( fid, '%i \r\n', Nmedia );
fprintf( fid, '%s \r\n', topopt );

% SSP
Depth = ocean_ssp(1,end);
fprintf( fid, '%i %f %6.1f  \r\n', Nmesh, sigma, Depth );
fprintf( fid, '%f   %6.5f  / \r\n', ocean_ssp);%注意聲速小數點位數該取幾位，會影響結果

% lower halfspace
fprintf( fid, ' ''%s''  0.0 \r\n',OPTIONS2 ); % OPTIONS2
fprintf( fid, '%f %f %f %f %f /  ! lower halfspace \r\n', Depth, cpb, csb, rhob,attb );

%fprintf( fid, '%f %f \r\n', cmin, cmax );
%fprintf( fid, '0.0,			! RMAX (km) \r\n' );

Nsd = length(sd);
fprintf( fid, '%i			! NSD \r\n', Nsd );
fprintf( fid, '%f  ', sd );
fprintf( fid, '! SD(1:NSD)  ... \r\n' );


fprintf( fid, '%i /		! NRD \r\n', Nrd );
fprintf( fid, ' %f  ', rd );
fprintf( fid, ' /		! RD(1:NRD)  ... \r\n' );

fprintf( fid, '%i /		! NRR \r\n', Nrr );
fprintf( fid, '%f   ', rr );
fprintf( fid, '/		! RR(1)  ... \r\n' );

fprintf( fid, '''%s'' \r\n', runtyp );
fprintf( fid, '%i \r\n', Nbeams );
fprintf( fid, '%f %f / \r\n', alpha );
fprintf( fid, '%f %f %f \n', step, zbox, rbox );
fclose( fid );

