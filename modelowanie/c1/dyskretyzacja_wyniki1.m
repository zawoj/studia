
figure
plot(t,y_wp,t,y_wt,t,y_tus,t,y_cont,'Linewidth',2)
hxl=xlabel('czas [s]');
set(hxl,'FontSize',14);
hl=legend('r�nica wprz�d','r�nica wstecz','Tustin','odpowied� uk�adu ci�g�ego')
set(hl,'FontSize',14);