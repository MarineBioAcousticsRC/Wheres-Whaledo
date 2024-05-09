%% large aperture:
sig_h1 = 7.99;
sig_h2 = 17.19;
sig_h3 = 8.5;
sig_h4 = 16.11;

sig_h = sqrt(sig_h2^2 + sig_h4^2)

sig_c = 0.135;
sig_tt = 6.5e-3;
sig_drift = .02;
sig_xcorr = 2.5e-9;

c = 1488.4;
maxTDOA_lrg = 1200/c;

sig_lrg = sqrt((sig_h/c)^2 + (sig_c*maxTDOA_lrg/c)^2 + sig_tt^2 + sig_drift^2 + sig_xcorr^2)

%% Small aperture:
sig_H1 = .274;
sig_H2 = 0.289;
sig_ray = 0.014;

maxTDOA_sml = 1.1/c;

sig_sml = sqrt((sig_H2/c)^2 + (1.1/c)^2*(1/35^2.*sig_h2^2 + sig_ray^2) + (sig_c*maxTDOA_sml/c)^2 + sig_xcorr^2)