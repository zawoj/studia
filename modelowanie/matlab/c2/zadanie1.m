% Skrypt do zadania 1: Identyfikacja funkcji statycznych
clear all; close all;

%% 1. Funkcje liniowe
disp('Funkcje liniowe:');
% Parametry bazowe: y = 0.5x + 0.6
figure(1); sgtitle('Regresja liniowa');

% Przykład 1: Mały szum, dużo punktów
x1 = 0:0.5:20; % 41 punktów
noise1 = 2*(rand(1, length(x1))-0.5); % Szum o amplitudzie 2
y1 = 0.5*x1 + 0.6;
yp1 = y1 + noise1;
A1 = [x1' ones(length(x1),1)];
b1 = yp1';
z1 = pinv(A1)*b1;
ye1 = z1(1)*x1 + z1(2);
subplot(3,1,1); plot(x1,y1,'b',x1,yp1,'r+',x1,ye1,'g','Linewidth',2);
title(['Linia 1: a = ', num2str(z1(1)), ', b = ', num2str(z1(2))]);
ee1 = (yp1-ye1)*(yp1-ye1)'; ep1 = (yp1-y1)*(yp1-y1)';
disp(['Linia 1 - ee: ', num2str(ee1), ', ep: ', num2str(ep1)]);

% Przykład 2: Duży szum, dużo punktów
x2 = 0:0.5:20;
noise2 = 10*(rand(1, length(x2))-0.5); % Szum o amplitudzie 10
y2 = 0.5*x2 + 0.6;
yp2 = y2 + noise2;
A2 = [x2' ones(length(x2),1)];
b2 = yp2';
z2 = pinv(A2)*b2;
ye2 = z2(1)*x2 + z2(2);
subplot(3,1,2); plot(x2,y2,'b',x2,yp2,'r+',x2,ye2,'g','Linewidth',2);
title(['Linia 2: a = ', num2str(z2(1)), ', b = ', num2str(z2(2))]);
ee2 = (yp2-ye2)*(yp2-ye2)'; ep2 = (yp2-y2)*(yp2-y2)';
disp(['Linia 2 - ee: ', num2str(ee2), ', ep: ', num2str(ep2)]);

% Przykład 3: Mały szum, mało punktów
x3 = 0:2:20; % 11 punktów
noise3 = 2*(rand(1, length(x3))-0.5);
y3 = 0.5*x3 + 0.6;
yp3 = y3 + noise3;
A3 = [x3' ones(length(x3),1)];
b3 = yp3';
z3 = pinv(A3)*b3;
ye3 = z3(1)*x3 + z3(2);
subplot(3,1,3); plot(x3,y3,'b',x3,yp3,'r+',x3,ye3,'g','Linewidth',2);
title(['Linia 3: a = ', num2str(z3(1)), ', b = ', num2str(z3(2))]);
ee3 = (yp3-ye3)*(yp3-ye3)'; ep3 = (yp3-y3)*(yp3-y3)';
disp(['Linia 3 - ee: ', num2str(ee3), ', ep: ', num2str(ep3)]);

hl = legend('Idealna funkcja', 'Zaszumione dane', 'Zidentyfikowana funkcja');
set(hl, 'FontSize', 10);

% Tworzenie folderu zad1 jeśli nie istnieje
if ~exist('zad1', 'dir')
    mkdir('zad1');
end

% Zapisanie wykresu do pliku PNG
saveas(gcf, 'zad1/regresja_liniowa.png');

%% 2. Parabole
disp('Parabole:');
% Parametry bazowe: y = 0.5x^2 + 0.7x + 0.6
figure(2); sgtitle('Regresja paraboliczna');

% Przykład 1: Średni szum, dużo punktów
x4 = 0:0.5:20;
noise4 = 30*(rand(1, length(x4))-0.5);
y4 = 0.5*(x4.^2) + 0.7*x4 + 0.6;
yp4 = y4 + noise4;
A4 = [(x4.^2)' x4' ones(length(x4),1)];
b4 = yp4';
z4 = pinv(A4)*b4;
ye4 = z4(1)*(x4.^2) + z4(2)*x4 + z4(3);
subplot(3,1,1); plot(x4,y4,'b',x4,yp4,'r+',x4,ye4,'g','Linewidth',2);
title(['Parabola 1: a = ', num2str(z4(1)), ', b = ', num2str(z4(2)), ', c = ', num2str(z4(3))]);
ee4 = (yp4-ye4)*(yp4-ye4)'; ep4 = (yp4-y4)*(yp4-y4)';
disp(['Parabola 1 - ee: ', num2str(ee4), ', ep: ', num2str(ep4)]);

% Przykład 2: Duży szum, dużo punktów
x5 = 0:0.5:20;
noise5 = 50*(rand(1, length(x5))-0.5);
y5 = 0.5*(x5.^2) + 0.7*x5 + 0.6;
yp5 = y5 + noise5;
A5 = [(x5.^2)' x5' ones(length(x5),1)];
b5 = yp5';
z5 = pinv(A5)*b5;
ye5 = z5(1)*(x5.^2) + z5(2)*x5 + z5(3);
subplot(3,1,2); plot(x5,y5,'b',x5,yp5,'r+',x5,ye5,'g','Linewidth',2);
title(['Parabola 2: a = ', num2str(z5(1)), ', b = ', num2str(z5(2)), ', c = ', num2str(z5(3))]);
ee5 = (yp5-ye5)*(yp5-ye5)'; ep5 = (yp5-y5)*(yp5-y5)';
disp(['Parabola 2 - ee: ', num2str(ee5), ', ep: ', num2str(ep5)]);

% Przykład 3: Średni szum, mało punktów
x6 = 0:2:20;
noise6 = 30*(rand(1, length(x6))-0.5);
y6 = 0.5*(x6.^2) + 0.7*x6 + 0.6;
yp6 = y6 + noise6;
A6 = [(x6.^2)' x6' ones(length(x6),1)];
b6 = yp6';
z6 = pinv(A6)*b6;
ye6 = z6(1)*(x6.^2) + z6(2)*x6 + z6(3);
subplot(3,1,3); plot(x6,y6,'b',x6,yp6,'r+',x6,ye6,'g','Linewidth',2);
title(['Parabola 3: a = ', num2str(z6(1)), ', b = ', num2str(z6(2)), ', c = ', num2str(z6(3))]);
ee6 = (yp6-ye6)*(yp6-ye6)'; ep6 = (yp6-y6)*(yp6-y6)';
disp(['Parabola 3 - ee: ', num2str(ee6), ', ep: ', num2str(ep6)]);

hl = legend('Idealna funkcja', 'Zaszumione dane', 'Zidentyfikowana funkcja');
set(hl, 'FontSize', 10);

% Zapisanie wykresu do pliku PNG
saveas(gcf, 'zad1/regresja_paraboliczna.png');

%% 3. Wielomiany 3. rzędu
disp('Wielomiany 3. rzędu:');
% Parametry bazowe: y = 0.1x^3 - 0.5x^2 + 0.7x + 0.6
figure(3); sgtitle('Regresja 3. rzędu');

% Przykład 1: Mały szum, dużo punktów
x7 = 0:0.5:20;
noise7 = 20*(rand(1, length(x7))-0.5);
y7 = 0.1*(x7.^3) - 0.5*(x7.^2) + 0.7*x7 + 0.6;
yp7 = y7 + noise7;
A7 = [(x7.^3)' (x7.^2)' x7' ones(length(x7),1)];
b7 = yp7';
z7 = pinv(A7)*b7;
ye7 = z7(1)*(x7.^3) + z7(2)*(x7.^2) + z7(3)*x7 + z7(4);
subplot(3,1,1); plot(x7,y7,'b',x7,yp7,'r+',x7,ye7,'g','Linewidth',2);
title(['Wielomian 1: a = ', num2str(z7(1)), ', b = ', num2str(z7(2)), ', c = ', num2str(z7(3)), ', d = ', num2str(z7(4))]);
ee7 = (yp7-ye7)*(yp7-ye7)'; ep7 = (yp7-y7)*(yp7-y7)';
disp(['Wielomian 1 - ee: ', num2str(ee7), ', ep: ', num2str(ep7)]);

% Przykład 2: Duży szum, dużo punktów
x8 = 0:0.5:20;
noise8 = 50*(rand(1, length(x8))-0.5);
y8 = 0.1*(x8.^3) - 0.5*(x8.^2) + 0.7*x8 + 0.6;
yp8 = y8 + noise8;
A8 = [(x8.^3)' (x8.^2)' x8' ones(length(x8),1)];
b8 = yp8';
z8 = pinv(A8)*b8;
ye8 = z8(1)*(x8.^3) + z8(2)*(x8.^2) + z8(3)*x8 + z8(4);
subplot(3,1,2); plot(x8,y8,'b',x8,yp8,'r+',x8,ye8,'g','Linewidth',2);
title(['Wielomian 2: a = ', num2str(z8(1)), ', b = ', num2str(z8(2)), ', c = ', num2str(z8(3)), ', d = ', num2str(z8(4))]);
ee8 = (yp8-ye8)*(yp8-ye8)'; ep8 = (yp8-y8)*(yp8-y8)';
disp(['Wielomian 2 - ee: ', num2str(ee8), ', ep: ', num2str(ep8)]);

% Przykład 3: Mały szum, mało punktów
x9 = 0:2:20;
noise9 = 20*(rand(1, length(x9))-0.5);
y9 = 0.1*(x9.^3) - 0.5*(x9.^2) + 0.7*x9 + 0.6;
yp9 = y9 + noise9;
A9 = [(x9.^3)' (x9.^2)' x9' ones(length(x9),1)];
b9 = yp9';
z9 = pinv(A9)*b9;
ye9 = z9(1)*(x9.^3) + z9(2)*(x9.^2) + z9(3)*x9 + z9(4);
subplot(3,1,3); plot(x9,y9,'b',x9,yp9,'r+',x9,ye9,'g','Linewidth',2);
title(['Wielomian 3: a = ', num2str(z9(1)), ', b = ', num2str(z9(2)), ', c = ', num2str(z9(3)), ', d = ', num2str(z9(4))]);
ee9 = (yp9-ye9)*(yp9-ye9)'; ep9 = (yp9-y9)*(yp9-y9)';
disp(['Wielomian 3 - ee: ', num2str(ee9), ', ep: ', num2str(ep9)]);

hl = legend('Idealna funkcja', 'Zaszumione dane', 'Zidentyfikowana funkcja');
set(hl, 'FontSize', 10);

% Zapisanie wykresu do pliku PNG
saveas(gcf, 'zad1/regresja_3_rzedu.png');