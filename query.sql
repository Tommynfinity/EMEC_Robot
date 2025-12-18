
SELECT 
    s.identification AS Sessione,
    s.id_basetta AS Basetta,

    COUNT(r.id) AS Totale,

    SUM(CASE WHEN r.esito = 'PASS' THEN 1 ELSE 0 END) AS Pezzi_OK,
    SUM(CASE WHEN r.esito = 'FAIL' THEN 1 ELSE 0 END) AS Pezzi_KO,

    ROUND(
        SUM(CASE WHEN r.esito = 'PASS' THEN 1 ELSE 0 END) 
        / NULLIF(COUNT(r.id), 0) * 100,
        1
    ) AS Percentuale_OK,

    MIN(r.data_test) AS Inizio_Test,
    MAX(r.data_test) AS Fine_Test

FROM sessione_test s
LEFT JOIN risultati_test r 
    ON s.id = r.sessione_id

GROUP BY 
    s.identification,
    s.id_basetta

ORDER BY Inizio_Test DESC;