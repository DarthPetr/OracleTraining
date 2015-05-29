--============================================
--Grants file for ROLES
host if exist Permissions\role_grants_script.sql del Permissions\role_grants_script.sql
set trimspool on linesize 5000
set serverout on size 1000000
set echo off
set termout off
set feedback off
set show off
set verify off
set define on
spool Permissions/role_grants_script.sql
@data/Permissions/role_grants.sql 
spool off
--============================================
