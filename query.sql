SELECT 
                s.id AS ID_Sessione,
                s.identification AS Sessione,
                s.id_basetta AS Basetta,
                COUNT(r.id) AS Totale,
                SUM(r.esito = 'PASS') AS Pezzi_OK,
                SUM(r.esito = 'FAIL') AS Pezzi_KO,
                ROUND(SUM(r.esito = 'PASS') / COUNT(r.id) * 100, 1) AS Percentuale_OK,
                MIN(r.data_test) AS Inizio_Test,
                MAX(r.data_test) AS Fine_Test
            FROM sessione_test s
            LEFT JOIN risultati_test r ON s.id = r.sessione_id
            GROUP BY s.id, s.identification, s.id_basetta
            ORDER BY s.data_creazione DESC;
