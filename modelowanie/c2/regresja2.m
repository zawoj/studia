t=0:20;
noise=0.1*(rand(1,21)-0.5);
y=1-exp(-0.3*t);
yp=y+noise;
A=[-t'];
b=real(log(1-yp')); %zabezpieczenie przy ujemnym argumencie dla logarytmu (z wyniku bierzemy czêœæ rzeczywist¹
z=pinv(A)*b;
ye=1-exp(-z(1)*t);
plot(x,y,x,yp,'+',x,ye,'Linewidth',2);
hl=legend('idealna funkcja','zaszumione dane','zidentyfinowana funkcja')
set(hl,'FontSize',14);

ee=(yp-ye)*(yp-ye)'
ep=(yp-y)*(yp-y)'
