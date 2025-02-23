x=0:20;
noise=2*(rand(1,21)-0.5);
y=0.5*x+0.6;
yp=y+noise;
A=[x' ones(21,1)];
b=yp';
z=pinv(A)*b;
ye=z(1)*x+z(2);
plot(x,y,x,yp,'+',x,ye,'Linewidth',2);
hl=legend('idealna funkcja','zaszumione dane','zidentyfinowana funkcja')
set(hl,'FontSize',14);
ee=(yp-ye)*(yp-ye)' %b³¹d estymacji
ep=(yp-y)*(yp-y)' %b³¹d danych

