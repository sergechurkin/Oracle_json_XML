CREATE OR REPLACE PROCEDURE CH.json_info
-- http://localhost:8080/dd/CH.json_info
AS
  l_str clob := '{"dt":"'||TO_CHAR(SYSDATE, 'DD.MM.YYYY HH24:MI:SS')||'","arr":[';
  l_flagstart BOOLEAN := true;
BEGIN
  OWA_UTIL.MIME_HEADER('application/json',FALSE,'utf-8');
  HTP.P('Access-Control-Allow-Origin: *');
  OWA_UTIL.HTTP_HEADER_CLOSE;
  FOR rec in (
    SELECT * FROM (
        SELECT LOWER(ses.username) username, 
               s.name sn,
               v.value time_proc
        FROM v$statname s, v$sesstat v, v$session ses 
        WHERE v.statistic# = s.statistic# 
          AND v.sid = ses.sid 
          AND v.value > 0 
          AND ses.username is not null
        ORDER BY ses.username
    ) PIVOT (
      SUM(time_proc) FOR sn IN ('CPU used by this session' cpu, 'DB time' db)
    ) WHERE rownum <= 8
  )
  LOOP
    IF (NOT l_flagstart) THEN
      l_str := l_str||',';
    END IF;
    l_flagstart := false;
    l_str := l_str||'{"user":"'||rec.username||'","cpu":"'||TO_CHAR(rec.cpu)||'","db":"'||TO_CHAR(rec.db)||'"}';
  END LOOP;
  HTP.PRN(l_str||']}');
EXCEPTION
  WHEN OTHERS THEN
    HTP.PRN('[{'||'"Error":"Ошибка в процедуре ch.json_info:'||SQLERRM||'"}]');
END json_info;
/