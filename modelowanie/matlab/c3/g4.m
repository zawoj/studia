% Identyfikacja układu ciągłego G4(s) = 1/(s + 2)

% Parametry symulacji
N = 200;                  % liczba próbek
ts_values = [0.1, 0.5, 1]; % różne okresy próbkowania do analizy

% Definicja układu ciągłego
num_c = [1];
den_c = [1, 2];
G4 = tf(num_c, den_c);

% Funkcja do identyfikacji układu G4
function [theta, singular_values] = identify_G4(u, y, ts, num_d_zoh, den_d_zoh, num_d_tustin, den_d_tustin)
    % Budowa macierzy Phi dla układu pierwszego rzędu
    Phi = [u(1:end-1)' -y(1:end-1)'];
    Y = y(2:end)';
    
    % Rozwiązanie metodą pseudoinwersji
    theta = pinv(Phi) * Y;
    
    % Analiza wartości szczególnych
    singular_values = svd(Phi);
    
    % Parametry modelu dyskretnego
    b0 = theta(1);
    a0 = theta(2);
    
    % Wyświetlenie wyników
    disp(['Okres próbkowania: Ts = ' num2str(ts)]);
    disp('Parametry zidentyfikowanego modelu dyskretnego:');
    disp(['b0 = ' num2str(b0) ', a0 = ' num2str(a0)]);
    
    % Porównanie z dyskretyzacją metodą ZOH
    disp('Parametry modelu zdyskretyzowanego metodą ZOH:');
    disp(['b0 = ' num2str(num_d_zoh(2)) ', a0 = ' num2str(-den_d_zoh(2))]);
    
    % Porównanie z dyskretyzacją metodą Tustina
    disp('Parametry modelu zdyskretyzowanego metodą Tustina:');
    disp(['b0 = ' num2str(num_d_tustin(2)) ', a0 = ' num2str(-den_d_tustin(2))]);
    
    % Obliczenie wartości własnych układu ciągłego z modelu dyskretnego
    % s = ln(z)/Ts
    z_pole = -a0;
    s_pole = log(z_pole)/ts;
    disp(['Estymowany biegun ciągły: s = ' num2str(s_pole)]);
    disp(['Rzeczywisty biegun ciągły: s = -2']);
    
    disp('Wartości szczególne:');
    disp(num2str(singular_values'));
end

% Funkcja do walidacji modelu G4
function validate_G4(u, y, theta, ts, t, G4_orig)
    b_id = [theta(1)];
    a_id = [1, theta(2)];
    
    % Model dyskretny
    G4_id = tf(b_id, a_id, ts);
    
    % Symulacja modelu zidentyfikowanego
    y_id = dlsim(b_id, a_id, u);
    
    % Obliczenie błędu średniokwadratowego (jako pojedyncza wartość)
    mse = mean((y(:) - y_id(:)).^2);
    
    % Wykresy
    figure('Position', [100, 100, 1000, 800]);
    
    % Pierwszy subplot - sygnał wejściowy
    subplot(4,1,1);
    plot(t, u, 'LineWidth', 1.5);
    title(['Walidacja modelu G4, Ts = ' num2str(ts)], 'FontSize', 14);
    ylabel('Wejście u(t)', 'FontSize', 12);
    grid on;
    xlim([0 10]);
    
    % Drugi subplot - porównanie odpowiedzi
    subplot(4,1,2);
    plot(t, y, 'b', t, y_id, 'r--', 'LineWidth', 1.5);
    legend('Odpowiedź układu ciągłego', 'Odpowiedź modelu dyskretnego');
    ylabel('Wyjście y(t)', 'FontSize', 12);
    grid on;
    xlim([0 10]);
    
    % Trzeci subplot - błąd predykcji
    subplot(4,1,3);
    error = y(:) - y_id(:);  % Upewniamy się, że mamy wektor kolumnowy
    plot(t, error, 'b', 'LineWidth', 1.5);  % Dodajemy kolor niebieski i zwiększamy grubość linii
    title(['Błąd predykcji, MSE = ' num2str(mse, '%.6f')], 'FontSize', 14);
    ylabel('Błąd', 'FontSize', 12);
    grid on;
    xlim([0 10]);
    % Automatyczne skalowanie osi Y z małym marginesem
    max_error = max(abs(error));
    if max_error > 0
        ylim([-max_error*1.2 max_error*1.2]);
    end
    
    % Czwarty subplot - charakterystyki częstotliwościowe
    subplot(4,1,4);
    w = logspace(-1, 2, 100);
    [mag_c, phase_c] = bode(G4_orig, w);
    [mag_d, phase_d] = bode(G4_id, w);
    semilogx(w, 20*log10(squeeze(mag_c)), 'b', w, 20*log10(squeeze(mag_d)), 'r--', 'LineWidth', 1.5);
    legend('Układ ciągły', 'Model dyskretny');
    title('Charakterystyka częstotliwościowa - amplituda', 'FontSize', 14);
    ylabel('Amplituda [dB]', 'FontSize', 12);
    xlabel('Częstotliwość [rad/s]', 'FontSize', 12);
    grid on;
    
    % Zapisanie wykresu do pliku PNG
    filename = ['G4_validation_Ts_' num2str(ts) '.png'];
    saveas(gcf, filename);
    close(gcf);  % Zamknięcie bieżącej figury
    
    % Wyświetlenie MSE jako pojedynczej wartości
    disp(['MSE dla modelu G4 (Ts = ' num2str(ts) '): ' num2str(mse, '%.6f')]);
end

% Analiza wpływu okresu próbkowania
for i = 1:length(ts_values)
    ts = ts_values(i);
    t = (0:N-1)*ts;
    
    % Dyskretyzacja układu ciągłego (do porównania)
    G4_d_zoh = c2d(G4, ts, 'zoh');
    [num_d_zoh, den_d_zoh] = tfdata(G4_d_zoh, 'v');
    
    G4_d_tustin = c2d(G4, ts, 'tustin');
    [num_d_tustin, den_d_tustin] = tfdata(G4_d_tustin, 'v');
    
    % Generacja sygnału wejściowego (losowego)
    rng(42); % dla powtarzalności
    u = rand(1, N);
    
    % Symulacja układu ciągłego z dyskretnym wejściem (zero-order hold)
    sys_c = ss(G4);
    [y, t] = lsim(sys_c, u, t);
    y = y';
    
    % Identyfikacja modelu
    disp(['===== IDENTYFIKACJA UKŁADU G4 DLA Ts = ' num2str(ts) ' =====']);
    [theta_g4, sv_g4] = identify_G4(u, y, ts, num_d_zoh, den_d_zoh, num_d_tustin, den_d_tustin);
    
    % Walidacja modelu
    validate_G4(u, y, theta_g4, ts, t, G4);
end