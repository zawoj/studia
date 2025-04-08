figure(1)
plot(t,u,t,y,'Linewidth',2);
hl=legend('wymuszenie u_k','odpowiedŸ uk³adu y_k');
set(hl,'FontSize',14);
figure(2)
plot(t,x,t,xe,'.','Linewidth',2);
hl=legend('zmienna stanu x_k','estymata zmiennej stanu x_k');
set(hl,'FontSize',14);

figure(3)
plot(t,par,t,ones(size(t))*0.95,'Linewidth',2);
hl=legend('estymowany parametr a','zadana wartoœæ parametru a');
set(hl,'FontSize',14);

