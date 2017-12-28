CREATE OR REPLACE PROCEDURE CH.xml_info
-- http://localhost:8080/dd/CH.xml_info
AS
  l_context     dbms_xmlgen.ctxhandle;
  l_returnvalue clob;
BEGIN
  OWA_UTIL.MIME_HEADER('text/xml',FALSE,'utf-8');
  HTP.P('Access-Control-Allow-Origin: *');
  OWA_UTIL.HTTP_HEADER_CLOSE;
  l_context := dbms_xmlgen.newcontext('
    SELECT TO_CHAR(SYSDATE, ''DD.MM.YYYY HH24:MI:SS'') dt, username, cpu, db FROM (
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
      SUM(time_proc) FOR sn IN (''CPU used by this session'' cpu, ''DB time'' db)
    )');

  l_returnvalue := dbms_xmlgen.getxml (l_context);
  dbms_xmlgen.closecontext (l_context);
  HTP.P(l_returnvalue);
EXCEPTION
  WHEN OTHERS THEN
    l_context := dbms_xmlgen.newcontext('select ''Ошибка в процедуре ch.json_info: '||SQLERRM||''' Error from dual');
    l_returnvalue := dbms_xmlgen.getxml (l_context);
    dbms_xmlgen.closecontext (l_context);
    HTP.P(l_returnvalue);
END xml_info;
/