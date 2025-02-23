
figure
plot(t,y_wp,t,y_wt,t,y_tus,t,y_cont,'Linewidth',2)
hxl=xlabel('czas [s]');
set(hxl,'FontSize',14);
hl=legend('ró¿nica wprzód','ró¿nica wstecz','Tustin','odpowiedŸ uk³adu ci¹g³ego')
set(hl,'FontSize',14);