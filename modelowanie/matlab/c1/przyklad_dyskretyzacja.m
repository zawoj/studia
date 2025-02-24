t=30

Ts=0.5;
td=0:Ts:10;
u_st=ones(size(td));
u_ln=td;

yr_st=1-exp(-t);
yr_imp=exp(-t);
yr_ln=t-1+exp(-t);

sys=tf([1],[1 1]);
sysd_imp=c2d(sys,Ts,'impulse');
[yy,tt]=step(sysd_imp);
[t_st_imp,y_st_imp]=stairs(tt,yy);

[yy,tt]=impulse(sysd_imp);
[t_imp_imp,y_imp_imp]=stairs(tt,yy);

[yy,tt]=lsim(sysd_imp,u_ln,td);
[t_ln_imp,y_ln_imp]=stairs(tt,yy);



figure
plot(t,yr_imp,t_imp_imp,y_imp_imp,'LineWidth',2);
title('Odpowied� impulsowa zdyskretyzowanego uk�adu metod� impulsow�');

figure
plot(t,yr_st,t_st_imp,y_st_imp,'LineWidth',2);
title('Odpowied� skokowa zdyskretyzowanego uk�adu metod� impulsow�');

figure
plot(t,yr_ln,t_ln_imp,y_ln_imp,'LineWidth',2);
title('Odpowied� na sygna� liniowo narastaj�cy zdyskretyzowanego uk�adu metod� impulsow�');

