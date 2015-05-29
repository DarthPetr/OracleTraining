set echo off
set termout on
prompt =========================
prompt  Invalid objects summary
prompt =========================

COLUMN object_name FORMAT A32 HEADING 'OBJECT NAME'
COLUMN object_type FORMAT A20 HEADING 'OBJECT TYPE'

select object_name, object_type
from user_objects
where status <> 'VALID';
set termout off
set termout on
prompt 
prompt ==========================================
prompt 
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