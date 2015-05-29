set echo off
set termout off

spool do_exit.sql
prompt set echo off
prompt set termout on
prompt
prompt prompt ================!!!!!!!!==================
prompt prompt EXIT the script!
prompt prompt ================!!!!!!!!==================
prompt
prompt pause
prompt host del "do_nothing.sql"
prompt exit 0
spool off
set define off
spool do_nothing.sql
prompt set echo off
prompt set termout on
prompt
prompt prompt OK! Continue running... &1
prompt set termout off
prompt
spool off
set define on
set termout off
def patch_dir=&1;
def patch_user_cr=&2;
def patch_role_p=&3;
def patch_skip_q=&4;

col script new_val script
def script = CRDS_USER@&_CONNECT_IDENTIFIER

select '&patch_user_cr' as script
  from dual
 where 'Y'=TRIM(upper('&patch_skip_q'));

def patch_user_cr = &script
--B===================Question 1==============
col script new_val script
def script = "q1.sql"

select 'do_nothing.sql' as script
  from dual
 where 'Y'=TRIM(upper('&patch_skip_q'));

@&script &1
--E===========================================

--B===================Question 2==============
col script new_val script
def script = "q2.sql"

select 'do_nothing.sql' as script
  from dual
 where 'Y'=TRIM(upper('&patch_skip_q'));

@&script &1
--E===========================================
set trimspool on linesize 5000
set serverout on size 1000000
set echo off
set termout off
set feedback off
set show off
set verify off
set define    on

var    CURR_PATCH_ID   number
var    LOG_NAME        varchar2(256)

rem---------------------------------------------------------------------------------!
rem- Assign patch ID and reg patch in AUDIT_PATCHES table
rem---------------------------------------------------------------------------------!
begin
 select '..\logs\'||
          lower(sys_context('USERENV','SESSION_USER')) ||'@'||
          lower(sys_context('USERENV','DB_NAME'))      ||'_'||
          to_char(sysdate,'yymmdd_hh24miss')           ||'.log'

  into :LOG_NAME from dual ; 

end  ;
/


begin

 dbms_application_info.set_action     ('&patch_dir')                       ; 
 dbms_application_info.set_client_info(TO_TIMESTAMP(SYSTIMESTAMP)) ;
 
 select nvl(max(id) + 1,1) into :CURR_PATCH_ID from audit_patches ; 

 insert into audit_patches
   (id, patch_name, os_user, session_user, module, ip_address, machine, terminal)
 values
   (:CURR_PATCH_ID
    ,'&patch_dir' 
    ,sys_context( 'USERENV','OS_USER')
    ,sys_context( 'USERENV','SESSION_USER')
    ,sys_context( 'USERENV','MODULE')
    ,sys_context( 'USERENV','IP_ADDRESS')
    ,sys_context( 'USERENV','HOST')
    ,sys_context( 'USERENV','TERMINAL') ) ; 
 commit ;  

exception
  when others then 
    select -9999 into :CURR_PATCH_ID from dual ; 
end  ;
/

set echo off
prompt =========================
prompt  BEFORE: Gather object versions...
prompt =========================
set echo on

begin
  pkg_audit_snapshot.create_snapshot('BEFORE', :CURR_PATCH_ID);
exception when others 
 then null;
end;
/

--logging------------------------
set   echo    OFF
set   termout OFF
set   define  ON

alter session set nls_date_format="dd-mm-yyyy hh24:mi:ss";
set  errorlogging ON
set  errorlogging ON identifier "'&patch_dir &_DATE'"
show errorlogging
---------------------------------

set   define  off
set   termout on
set   echo    on

spool temp_log.log


rem---------------------------------------------------------------------------------!
rem- Run start script
rem---------------------------------------------------------------------------------!
@2_before

rem---------------------------------------------------------------------------------!
rem- Run main script
rem---------------------------------------------------------------------------------!
@1_main

rem---------------------------------------------------------------------------------!
rem- Run final script
rem---------------------------------------------------------------------------------!
@3_after

set echo off
prompt =========================
prompt  Rebuilding schema ...
prompt =========================
set echo on
exec dbms_utility.compile_schema(user, false);

set echo off
prompt =========================
prompt  AFTER: Gather object versions...
prompt =========================
set echo on

begin
  pkg_audit_snapshot.create_snapshot('AFTER', :CURR_PATCH_ID);
exception when others 
 then null;
end;
/

prompt =========================
prompt  Invalid objects summary
prompt =========================
COLUMN object_name FORMAT A32 HEADING 'OBJECT NAME'
COLUMN object_type FORMAT A20 HEADING 'OBJECT TYPE'

select object_name, object_type
from user_objects
where status <> 'VALID';


rem---------------------------------------------------------------------------------!
rem- Unable or disable pause during deployment
rem---------------------------------------------------------------------------------!

set define on
col question new_val question
def question = "Q3.sql"
set termout off

select 'do_nothing.sql' as question
  from dual
where 'Y'=TRIM(upper('&patch_skip_q'));

@&question	


set define off
set echo    off
set termout off

rem---------------------------------------------------------------------------------!
rem- Update AUDIT_PATCHES set FINISHED field
rem---------------------------------------------------------------------------------!
begin
 update audit_patches 
  set FINISHED = sysdate
   where id = :CURR_PATCH_ID ;
 commit ;  
end  ;
/

set echo    on
set termout on


rem---------------------------------------------------------------------------------!
rem- Get patch report
rem---------------------------------------------------------------------------------!

prompt ;
prompt ;
prompt ;
prompt===============================================================================;
prompt==                                                                           ==; 
prompt==                    DDL operations during current PATCH                    ==; 
prompt==                                                                           ==; 
prompt===============================================================================;

COLUMN obj_name   FORMAT A30 ;     
COLUMN ddl_event  FORMAT A30 ;     
COLUMN status     FORMAT A7  ;     
COLUMN created    FORMAT A8  ; 

 select t.obj_name, t.ddl_event, o.status, to_char(t.created,'hh24:mi:ss') DDL_time 
   from AUDIT_DDL t, user_objects o 
     where t.created >= sys_context( 'USERENV','CLIENT_INFO')
       and o.OBJECT_NAME(+) = t.obj_name 
       and o.OBJECT_TYPE(+) = t.obj_type
    order by o.status, o.OBJECT_NAME, t.created ;

prompt ;
prompt.                                          See table AUDIT_DDL for details ... ;

prompt===============================================================================;
prompt==                                                                           ==; 
prompt==                    List of ERRORS during current PATCH                    ==; 
prompt==                                                                           ==; 
prompt===============================================================================;

COLUMN err_code       FORMAT A10  ;     
COLUMN error_message  FORMAT A100 ;     
COLUMN cnt            FORMAT A3   ;     

select regexp_substr(cast(s.message as varchar2(4000)), 'ORA-[0-9]+') err_code
      ,cast(s.message as varchar2(4000)) error_message
      ,to_char(count(*)) cnt
  from SPERRORLOG s
 where s.timestamp >= sys_context( 'USERENV','CLIENT_INFO')
 group by regexp_substr(cast(s.message as varchar2(4000)), 'ORA-[0-9]+')
         ,cast(s.message as varchar2(4000))
 order by 1, 2, 3;

prompt ;
prompt.                                         See table SPERRORLOG for details ... ;

prompt ;
prompt ;
prompt ;
prompt===============================================================================;
prompt==                                                                           ==; 
prompt==                           PATCH Info                                      ==; 
prompt==                                                                           ==; 
prompt===============================================================================;

COLUMN ID           FORMAT 999999 ;     
COLUMN patch_name   FORMAT A25    ;     
COLUMN started      FORMAT A20    ;     
COLUMN finished     FORMAT A20    ;     

  select t.id, t.patch_name, 
         to_char(t.started ,'dd.mm.yyyy hh24:mi:ss') started,
         to_char(t.finished,'dd.mm.yyyy hh24:mi:ss') finished 
    from AUDIT_PATCHES t where t.id = :CURR_PATCH_ID ;

prompt ;
prompt.                                     See table AUDIT_PATCHES for details ... ;
prompt ;
prompt ;
prompt ;

spool off

rem---------------------------------------------------------------------------------!
set   echo    off
set   termout off
set   head    off
set   define  off

host if exist gen_upd_spool.bat del gen_upd_spool.bat

rem---------------------------------------------------------------------------------!
rem- Generate gen_upd_spool.bat which generate SQL+ script for update AUDIT_PATCHES
rem---------------------------------------------------------------------------------!

spool  gen_upd_spool.bat

select '@echo off'                                                       from dual ;
select 'if exist save_log.sql del save_log.sql'                          from dual ;

select 'setlocal enabledelayedexpansion'                                 from dual ;

rem------------------------------------------------------------!
rem- in the next row var SELECT_LINE define number of 
rem-      lines for dividing log file  
rem------------------------------------------------------------!

select 'set select_line=128'                                             from dual ;


select 'set quote='''                                                    from dual ;
select 'set replace=~'                                                   from dual ;
                                                                                     
select 'echo declare v_log clob ;      >>save_log.sql'                   from dual ;
select 'echo begin                     >>save_log.sql'                   from dual ;
select 'echo v_log := CONCAT(v_log,''  >>save_log.sql'                   from dual ;
                                                                                     
select 'set  cnt=0'                                                      from dual ;
select 'for /F "tokens=* usebackq delims=" %%i in ("temp_log.log") Do (' from dual ;
select '  set /a cnt+=1'                                                 from dual ;
select '  set  line=%%i'                                                 from dual ;
select '  set out_line=!line:%quote%=%replace%!'                         from dual ;
select '  if !cnt! GEQ %select_line% ('                                  from dual ;
select '   set cnt=0'                                                    from dual ;
select '    echo !out_line!                >>save_log.sql'               from dual ;
select '    echo ''^)^;                    >>save_log.sql'               from dual ;
select '    echo v_log := CONCAT(v_log,''  >>save_log.sql'               from dual ;
select '  ) else ('                                                      from dual ;
select '         echo !out_line!           >>save_log.sql'               from dual ;
select '        ) '                                                      from dual ;
select ')'                                                               from dual ;
select 'echo '') ;                                    >>save_log.sql'    from dual ;
select 'echo   update audit_patches set SPOOL = v_log >>save_log.sql'    from dual ;
select 'echo    where id = '||:CURR_PATCH_ID||' ;     >>save_log.sql'    from dual ;
select 'echo   commit ;                               >>save_log.sql'    from dual ;
select 'echo end  ;                                   >>save_log.sql'    from dual ;
select 'echo /                                        >>save_log.sql'    from dual ;


select 'copy /Y temp_log.log '||&LOG_NAME||' >nul &del temp_log.log'     from dual ; 
rem---------------------------------------------------------------------------------!

spool off

rem---------------------------------------------------------------------------------!
rem- Generate scripts for grants and synonyms
rem---------------------------------------------------------------------------------!
@3_1_Gen_Grants_and_Synonyms.sql
rem---------------------------------------------------------------------------------!
rem- Install Grants
rem---------------------------------------------------------------------------------!
set termout on
set echo on
@Permissions/role_grants_script.sql
host if exist Permissions\role_grants_script.sql del Permissions\role_grants_script.sql

rem---------------------------------------------------------------------------------!
rem- Run generated BAT file to generate SQL+ script 
rem---------------------------------------------------------------------------------!
host gen_upd_spool.bat

rem---------------------------------------------------------------------------------!
rem- Run SQL+ script
rem---------------------------------------------------------------------------------!
@save_log.sql


set   termout off
rem---------------------------------------------------------------------------------!
 host del gen_upd_spool.bat
 host del save_log.sql
host del do_nothing.sql
host del do_exit.sql
exit ;
