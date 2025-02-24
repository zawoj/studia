
figure
plot(t,y_wp,t,y_wt,t,y_tus,t,y_cont,'Linewidth',2)
hxl=xlabel('czas [s]');
set(hxl,'FontSize',14);
hl=legend('różnica wprzód','różnica wstecz','Tustin','odpowiedź układu ciągłego')
set(hl,'FontSize',14);