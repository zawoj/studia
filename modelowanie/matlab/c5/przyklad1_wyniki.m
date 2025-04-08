figure(1)
plot(t(5:end),x1,t(5:end),x2,t(5:end),xe1,t(5:end),xe2,'Linewidth',2);
hl=legend('zmienna stanu x_1','zmienna stanu x_1','estymata x_1','estymata x_2');
set(hl,'FontSize',14);
figure(2)
plot(t,y,t,u,'Linewidth',2);
hl=legend('odpowiedü y(t)','wymuszenie u(t)');
set(hl,'FontSize',14);

