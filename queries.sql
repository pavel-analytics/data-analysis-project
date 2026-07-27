-- ЗАПРОС 1. Анализ операционных показателей по часам и поиск аномалий
SELECT 
    address,
    EXTRACT(HOUR FROM time_payment) AS payment_hour,
    COUNT(id_transaction) AS total_transactions,
    AVG(EXTRACT(EPOCH FROM (time_payment_fixe - time_payment))) AS avg_duration_seconds
FROM data_table
WHERE time_payment BETWEEN '2022-09-01 00:00:00' AND '2022-09-01 23:59:59'
GROUP BY address, EXTRACT(HOUR FROM time_payment)
ORDER BY address, payment_hour;


-- ЗАПРОС 2. Маркетинговый анализ эффективности программы лояльности
SELECT 
    COUNT(id_transaction) AS loyalty_transactions,
    AVG(sum_payment) AS avg_cheque,
    AVG(sum_payment * loyal_prog) AS avg_discount_rub,
    SUM(flag_self_service) * 100.0 / COUNT(*) AS self_service_share_pct
FROM data_table
WHERE loyal_prog > 0
  AND time_payment BETWEEN '2022-09-01' AND '2022-09-07';


-- ЗАПРОС 3. Инфраструктурный анализ производительности серверов
SELECT 
    payment_system,
    server AS old_server_id,
    new_server AS new_server_id,
    COUNT(id_transaction) AS total_operations,
    AVG(len) AS avg_transaction_duration,
    SUM(flag_debit_card) AS total_debit_cards
FROM data_table
WHERE day = 1
GROUP BY payment_system, server, new_server
ORDER BY avg_transaction_duration ASC;


-- ЗАПРОС 4. Анализ технических сбоев и моделирование новой программы лояльности (ТЗ 2)
SELECT 
    address,
    -- Категоризируем операции: если длительность > 300 сек, помечаем как технический сбой
    CASE 
        WHEN len > 300 THEN 'Технический сбой'
        ELSE 'Штатный режим'
    END AS operation_status,
    
    -- Считаем базовые показатели
    COUNT(id_transaction) AS total_transactions,
    SUM(sum_payment) AS actual_revenue,
    
    -- Моделируем экономику по формуле из Excel (восстановление полной стоимости чека и расчет новой скидки)
    SUM(
        CASE 
            WHEN loyal_prog < 1 THEN (sum_payment / (1.0 - loyal_prog)) * new_loyal_prog
            ELSE 0 
        END
    ) AS modeled_new_discount_rub,
    
    -- Считаем потенциальные потери выручки во время сбоев
    SUM(CASE WHEN len > 300 THEN sum_payment ELSE 0 END) AS revenue_at_risk
FROM data_table
WHERE day BETWEEN 1 AND 7
GROUP BY address, 
         CASE WHEN len > 300 THEN 'Технический сбой' ELSE 'Штатный режим' END
ORDER BY revenue_at_risk DESC;
