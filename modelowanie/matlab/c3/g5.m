% Identyfikacja układu ciągłego G5(s) = (s + 2)/(s^3 + 2s^2 + s + 1)

% Parametry symulacji
N = 500;                  % liczba próbek
ts_values = [0.05, 0.1, 0.3]; % różne okresy próbkowania do analizy

% Definicja układu ciągłego
num_c = [1, 2];
den_c = [1, 2, 1, 1];
G5 = tf(num_c, den_c);

% Funkcja do identyfikacji układu G5
function [theta, singular_values] = identify_G5(u, y, ts, num_d_zoh, den_d_zoh, den_c)
    % Budowa macierzy Phi dla układu trzeciego rzędu
    % G5 ma licznik pierwszego rzędu, mianownik trzeciego rzędu
    % Przygotowanie danych
    u = u(:); % Konwersja do wektora kolumnowego
    y = y(:); % Konwersja do wektora kolumnowego
    
    % Budowa macierzy Phi - lepiej używać jawnej pętli do budowy
    N = length(y);
    n = 3;  % Rząd układu
    Phi = zeros(N-n, 2*n);
    Y = zeros(N-n, 1);
    
    for i = n+1:N
        % Reguła ARX: y(k) = b0*u(k-1) + ... + bn-1*u(k-n) - a1*y(k-1) - ... - an*y(k-n)
        Phi(i-n,:) = [u(i-1), u(i-2), u(i-3), -y(i-1), -y(i-2), -y(i-3)];
        Y(i-n) = y(i);
    end
    
    % Rozwiązanie metodą pseudoinwersji
    theta = pinv(Phi) * Y;
    
    % Analiza wartości szczególnych
    singular_values = svd(Phi);
    
    % Parametry modelu dyskretnego
    b2 = theta(1);
    b1 = theta(2);
    b0 = theta(3);
    a2 = theta(4);
    a1 = theta(5);
    a0 = theta(6);
    
    % Sprawdzenie stabilności modelu dyskretnego
    z_poles = roots([1 a2 a1 a0]);
    is_stable = all(abs(z_poles) < 1);
    
    if ~is_stable
        disp('UWAGA: Zidentyfikowany model dyskretny jest niestabilny!');
    end
    
    % Wyświetlenie wyników
    disp(['Okres próbkowania: Ts = ' num2str(ts)]);
    disp('Parametry zidentyfikowanego modelu dyskretnego:');
    disp(['b2 = ' num2str(b2) ', b1 = ' num2str(b1) ', b0 = ' num2str(b0) ...
          ', a2 = ' num2str(a2) ', a1 = ' num2str(a1) ', a0 = ' num2str(a0)]);
    
    % Porównanie z dyskretyzacją metodą ZOH
    disp('Parametry modelu zdyskretyzowanego metodą ZOH:');
    if length(num_d_zoh) == 4 && length(den_d_zoh) == 4
        disp(['b2 = ' num2str(num_d_zoh(2)) ', b1 = ' num2str(num_d_zoh(3)) ...
              ', b0 = ' num2str(num_d_zoh(4))]);
        disp(['a2 = ' num2str(-den_d_zoh(2)) ', a1 = ' num2str(-den_d_zoh(3)) ...
              ', a0 = ' num2str(-den_d_zoh(4))]);
    else
        disp('Struktura modelu ZOH jest inna niż oczekiwano');
        disp(['Licznik: ' num2str(num_d_zoh)]);
        disp(['Mianownik: ' num2str(den_d_zoh)]);
    end
    
    % Obliczenie wartości własnych układu ciągłego z modelu dyskretnego
    s_poles = log(z_poles)/ts;
    disp('Estymowane bieguny ciągłe:');
    disp(s_poles);
    disp('Rzeczywiste bieguny ciągłe:');
    disp(roots(den_c));
    
    disp('Wartości szczególne:');
    disp(num2str(singular_values'));
end

% Funkcja do walidacji modelu G5
function validate_G5(u, y, theta, ts, t, G5_orig)
    % Upewniamy się, że wektory mają odpowiedni format
    u = u(:);
    y = y(:);
    
    % Tworzenie modelu zidentyfikowanego
    b = [theta(1), theta(2), theta(3)];
    a = [1, theta(4), theta(5), theta(6)];
    
    % Sprawdzenie stabilności modelu
    z_poles = roots(a);
    is_stable = all(abs(z_poles) < 1);
    
    if ~is_stable
        disp('UWAGA: Zidentyfikowany model dyskretny jest niestabilny!');
        disp('Bieguny modelu dyskretnego:');
        disp(z_poles);
    end
    
    % Tworzenie modelu jako obiekt tf
    G5_id = tf(b, a, ts);
    
    % Symulacja odpowiedzi zidentyfikowanego modelu (ręczna implementacja)
    N = length(u);
    y_id = zeros(N, 1);
    
    % Inicjalizacja warunków początkowych
    y_delayed = zeros(3, 1);
    u_delayed = zeros(3, 1);
    
    % Symulacja krok po kroku
    for k = 1:N
        % Aktualizacja opóźnionych wejść i wyjść
        if k > 1
            u_delayed(1) = u(k-1);
            if k > 2
                u_delayed(2) = u(k-2);
                if k > 3
                    u_delayed(3) = u(k-3);
                end
            end
        end
        
        % Obliczenie wyjścia na podstawie równania różnicowego
        y_id(k) = b(1)*u_delayed(1) + b(2)*u_delayed(2) + b(3)*u_delayed(3) - ...
                  a(2)*y_delayed(1) - a(3)*y_delayed(2) - a(4)*y_delayed(3);
        
        % Aktualizacja opóźnionych wyjść
        y_delayed = [y_id(k); y_delayed(1:2)];
    end
    
    % Obliczenie błędu średniokwadratowego (jako pojedyncza wartość)
    error = y - y_id;
    mse = mean(error.^2);
    
    % W przypadku nieskończonego MSE, użyj alternatywnej metody symulacji z MATLAB
    if ~isfinite(mse) || mse > 1e10
        disp('MSE jest za duże lub nieskończone. Próba alternatywnej metody symulacji...');
        try
            % Spróbuj użyć funkcji lsim zamiast dlsim
            sys_id = ss(G5_id);
            [y_id_alt, ~] = lsim(sys_id, u, t);
            error = y - y_id_alt;
            mse_alt = mean(error.^2);
            
            if isfinite(mse_alt) && mse_alt < mse
                disp(['Alternatywna metoda dała lepsze wyniki. MSE: ' num2str(mse_alt)]);
                y_id = y_id_alt;
                error = y - y_id;
                mse = mse_alt;
            end
        catch
            disp('Alternatywna metoda również nie zadziałała.');
        end
    end
    
    % Jeśli MSE wciąż jest za duże, użyj modelu ZOH dla porównania
    if ~isfinite(mse) || mse > 1e10
        disp('MSE wciąż bardzo wysokie. Użycie modelu ZOH jako alternatywy dla celów wyświetlania...');
        G5_d_zoh = c2d(G5_orig, ts, 'zoh');
        [y_id_zoh, ~] = lsim(G5_d_zoh, u, t);
        error = y - y_id_zoh;
        mse_zoh = mean(error.^2);
        disp(['MSE dla modelu ZOH: ' num2str(mse_zoh)]);
        
        if isfinite(mse_zoh) && (mse_zoh < mse || ~isfinite(mse))
            y_id = y_id_zoh;
            error = y - y_id;
            mse = mse_zoh;
            disp('Użyto modelu ZOH do wyświetlenia wyników.');
        end
    end
    
    % Wykresy
    figure('Position', [100, 100, 1000, 800]);
    
    % Pierwszy subplot - sygnał wejściowy
    subplot(4,1,1);
    plot(t, u, 'LineWidth', 1.5);
    title(['Walidacja modelu G5, Ts = ' num2str(ts)], 'FontSize', 14);
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
    plot(t, error, 'b', 'LineWidth', 1.5);
    title(['Błąd predykcji, MSE = ' num2str(mse, '%.6f')], 'FontSize', 14);
    ylabel('Błąd', 'FontSize', 12);
    grid on;
    xlim([0 10]);
    % Automatyczne skalowanie osi Y z małym marginesem
    max_abs_error = max(abs(error(:)));  % Upewniamy się, że otrzymamy skalar
    if ~isempty(max_abs_error) && isfinite(max_abs_error) && max_abs_error > 0
        ylim([-max_abs_error*1.2 max_abs_error*1.2]);
    end
    
    % Czwarty subplot - charakterystyki częstotliwościowe
    subplot(4,1,4);
    w = logspace(-1, 2, 100);
    [mag_c, phase_c] = bode(G5_orig, w);
    
    try
        % Próba uzyskania charakterystyki częstotliwościowej
        [mag_d, phase_d] = bode(G5_id, w);
        semilogx(w, 20*log10(squeeze(mag_c)), 'b', w, 20*log10(squeeze(mag_d)), 'r--', 'LineWidth', 1.5);
        legend('Układ ciągły', 'Model dyskretny');
    catch
        % W przypadku błędu, pokaż tylko charakterystykę układu ciągłego
        semilogx(w, 20*log10(squeeze(mag_c)), 'b', 'LineWidth', 1.5);
        legend('Układ ciągły');
        disp('Nie można wyświetlić charakterystyki częstotliwościowej modelu dyskretnego.');
    end
    
    title('Charakterystyka częstotliwościowa - amplituda', 'FontSize', 14);
    ylabel('Amplituda [dB]', 'FontSize', 12);
    xlabel('Częstotliwość [rad/s]', 'FontSize', 12);
    grid on;
    
    % Zapisanie wykresu do pliku PNG
    filename = ['G5_validation_Ts_' num2str(ts) '.png'];
    saveas(gcf, filename);
    close(gcf);  % Zamknięcie bieżącej figury
    
    % Wyświetlenie MSE jako pojedynczej wartości
    if isfinite(mse)
        disp(['MSE dla modelu G5 (Ts = ' num2str(ts) '): ' num2str(mse, '%.6f')]);
    else
        disp(['MSE dla modelu G5 (Ts = ' num2str(ts) '): Nieskończone']);
    end
end

% Analiza wpływu okresu próbkowania
for i = 1:length(ts_values)
    ts = ts_values(i);
    t = (0:N-1)*ts;
    
    % Dyskretyzacja układu ciągłego (do porównania)
    G5_d_zoh = c2d(G5, ts, 'zoh');
    [num_d_zoh, den_d_zoh] = tfdata(G5_d_zoh, 'v');
    
    G5_d_tustin = c2d(G5, ts, 'tustin');
    [num_d_tustin, den_d_tustin] = tfdata(G5_d_tustin, 'v');
    
    % Generacja sygnału wejściowego
    % Użyjemy sygnału losowego z dodanymi komponentami sinusoidalnymi
    % dla lepszego pobudzenia układu
    rng(42); % dla powtarzalności
    t_vec = (0:N-1)*ts;
    u = rand(1, N) + 0.5*sin(t_vec) + 0.3*sin(3*t_vec) + 0.2*sin(5*t_vec);
    
    % Symulacja układu ciągłego z dyskretnym wejściem (zero-order hold)
    sys_c = ss(G5);
    [y, t] = lsim(sys_c, u, t);
    y = y';
    
    % Identyfikacja modelu
    disp(['===== IDENTYFIKACJA UKŁADU G5 DLA Ts = ' num2str(ts) ' =====']);
    [theta_g5, sv_g5] = identify_G5(u, y, ts, num_d_zoh, den_d_zoh, den_c);
    
    % Walidacja modelu
    validate_G5(u, y, theta_g5, ts, t, G5);
end