declare
  v_from_schema        varchar2(30 char) := user;
  v_user_objects_list  strarray := strarray();
  v_unused_tables_list strarray := strarray();

  --========================================================      
  procedure p_grant_objects(ip_object_name in strarray
                           ,ip_object_type in varchar2
                           ,ip_privilege   in varchar2
                           ,ip_from_schema in varchar2
                           ,ip_to_schema   in varchar2) is
    v_from_schema varchar2(30) := nvl(upper(ip_from_schema), 'STG_OWNER');
    v_to_schema   varchar2(30) := nvl(upper(ip_to_schema), 'STG_USER');
    v_object_type varchar2(30) := nvl(upper(ip_object_type), '');
    v_privilege   varchar2(30) := nvl(upper(ip_privilege), '');
  
    cursor cur is
    --input objects
      with in_objs as
       (select upper(column_value) as Object_Name
          from table(ip_object_name)),
      --existetd objects with defined type
      qr_objs as
       (select /*+ materialize */
         coalesce(o.table_name, io.Object_Name) as Object_Name
        ,coalesce(nvl2(o.table_name, null, 'grant'), nvl2(io.Object_Name, null, 'revoke')) as method
        ,v_privilege as Operation
          from user_tables o
         inner join user_tab_privs p
            on (o.table_name = p.table_name and o.nested = 'NO' and o.TABLE_NAME not like 'SYS%' and
               p.grantee = v_to_schema and p.grantor = v_from_schema and p.privilege = v_privilege)
          full join in_objs io
            on (o.table_name = io.object_name)
          left join user_tables o2
            on (io.object_name = o2.table_name)
         where ((o.table_name is null and o2.table_name is not null) or io.Object_Name is null))
      
      select *
        from (select method || ' ' || Operation || ' on ' || Object_Name ||
                     decode(method, 'grant', ' to ', 'revoke', ' from ') || v_to_schema as sql_txt
                    ,initcap(Operation) || ' privilege for ' || Object_Name || ' was ' || method || 'ed.' as put_txt
                from qr_objs
               order by Object_Name
                       ,Operation);
  begin
    for rec in cur
    loop
      begin
        dbms_output.put_line(rec.sql_txt || ';');
        dbms_output.put_line('prompt ' || rec.put_txt);
        --
      exception
        when others then
          dbms_output.put_line('prompt ' || sqlerrm || ' for: ' || rec.sql_txt);
      end;
    end loop;
  end p_grant_objects;

begin

  if v_from_schema in ('STG_OWNER', 'STG_OWNER_QA') then
    select u.TABLE_NAME bulk collect
      into v_user_objects_list
      from user_tables u
     where u.TABLESPACE_NAME is not null
       and u.NESTED = 'NO'
       and u.TABLE_NAME not like 'SYS%';
    dbms_output.put_line('set define    off');
    dbms_output.put_line('set termout   on');
    dbms_output.put_line('set echo      off');
    dbms_output.put_line('set serverout on size 1000000');
    dbms_output.put_line('spool ../logs/' || 'grant_roles' || '_' || lower(sys_context('USERENV', 'SESSION_USER')) || '_' ||
                         lower(sys_context('USERENV', 'DB_NAME')) || '_' || to_char(sysdate, 'yymmdd_hh24miss') ||
                         '.log');
    dbms_output.put_line('');
    dbms_output.put_line('prompt ==========================================');
    dbms_output.put_line('prompt  Manage Grants for OWNER`s objects to ROLES');
    dbms_output.put_line('prompt ==========================================');
    dbms_output.put_line('prompt =========================');
    dbms_output.put_line('prompt Date: ' || to_char(sysdate, 'DD-MM-YYYY HH24:MI'));
    dbms_output.put_line('prompt =========================');
    dbms_output.put_line('');
    --grant/revoke update for ROLE_USER_GRANT_UPDATE
    dbms_output.put_line('prompt =========================');
    dbms_output.put_line('prompt GRANTS for ROLE_USER_GRANT_UPDATE');
    dbms_output.put_line('prompt =========================');
    p_grant_objects(ip_object_name => v_user_objects_list multiset except v_unused_tables_list
                   ,ip_object_type => 'TABLE'
                   ,ip_privilege   => 'UPDATE'
                   ,ip_from_schema => v_from_schema
                   ,ip_to_schema   => 'ROLE_USER_GRANT_UPDATE');
    dbms_output.put_line('');
    dbms_output.put_line('prompt Done.');
    dbms_output.put_line('');
    --grant/revoke insert for ROLE_USER_GRANT_INSERT
    dbms_output.put_line('prompt =========================');
    dbms_output.put_line('prompt GRANTS for ROLE_USER_GRANT_INSERT');
    dbms_output.put_line('prompt =========================');
    p_grant_objects(ip_object_name => v_user_objects_list multiset except v_unused_tables_list
                   ,ip_object_type => 'TABLE'
                   ,ip_privilege   => 'INSERT'
                   ,ip_from_schema => v_from_schema
                   ,ip_to_schema   => 'ROLE_USER_GRANT_INSERT');
    dbms_output.put_line('');
    dbms_output.put_line('prompt Done.');
    dbms_output.put_line('');
    --grant/revoke update for ROLE_USER_GRANT_DELETE
    dbms_output.put_line('prompt =========================');
    dbms_output.put_line('prompt GRANTS for ROLE_USER_GRANT_DELETE');
    dbms_output.put_line('prompt =========================');
    p_grant_objects(ip_object_name => v_user_objects_list multiset except v_unused_tables_list
                   ,ip_object_type => 'TABLE'
                   ,ip_privilege   => 'DELETE'
                   ,ip_from_schema => v_from_schema
                   ,ip_to_schema   => 'ROLE_USER_GRANT_DELETE');
    --grant/revoke update for ROLE_USER_GRANT_READ
    dbms_output.put_line('prompt =========================');
    dbms_output.put_line('prompt GRANTS for ROLE_USER_GRANT_READ');
    dbms_output.put_line('prompt =========================');
    p_grant_objects(ip_object_name => v_user_objects_list
                   ,ip_object_type => 'TABLE'
                   ,ip_privilege   => 'SELECT'
                   ,ip_from_schema => v_from_schema
                   ,ip_to_schema   => 'ROLE_USER_GRANT_READ');
    dbms_output.put_line('');
    dbms_output.put_line('prompt Done.');
    dbms_output.put_line('');
    dbms_output.put_line('spool off');
  
  end if;
end;
/
