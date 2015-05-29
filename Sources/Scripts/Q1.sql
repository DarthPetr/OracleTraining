set echo off
set termout on
prompt 
prompt 
prompt ==========================================
prompt Patch: &1
prompt You are connected as: "&_USER@&_CONNECT_IDENTIFIER"
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt Are you sure to run the script? (Y/N):
accept vv_answer_01 CHAR DEFAULT 'N'
prompt ==========================================
prompt 
prompt 
set termout off
col script new_val script
def script = "do_exit.sql"

select 'do_nothing.sql' as script
  from dual
 where 'Y'=upper('&vv_answer_01');

@&script
set termout off