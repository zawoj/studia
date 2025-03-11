figure(1)
plot(t(3:end),theta(:,1),t(3:end),theta(:,2),t(3:end),par(3:end),'Linewidth',2);
hl=legend('parametr a_0','parametr b_0','zadawany parametr b_0');
set(hl,'FontSize',14);
figure(2)
plot(t(3:end),squeeze(P(1,1,:)),t(3:end),squeeze(P(2,2,:)) ,'Linewidth',2);
hl=legend('P(1,1)_k','P(2,2)_k');
set(hl,'FontSize',14);

