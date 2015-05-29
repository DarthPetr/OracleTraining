declare
  lv_user varchar2(30);
begin
  select sys_context('userenv', 'CURRENT_SCHEMA')
    into lv_user
    from dual;
  dbms_stats.gather_table_stats(lv_user
                               ,upper('Table_name')
                               ,estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE
                               ,method_opt => 'FOR ALL COLUMNS SIZE AUTO');
end;
/
