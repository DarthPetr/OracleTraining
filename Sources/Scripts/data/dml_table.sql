declare 
  v_ins_val_arr      strarray:=strarray();

  procedure p_ins(
            ip_client_type_id in table_name.client_type_id%type,
            ip_client_type_cd in table_name.client_type_cd%type,
            ip_client_type_descr in table_name.client_type_descr%type,
            ip_status_cd in table_name.status_cd%type,
            ip_file_id in table_name.file_id%type,
            op_ins_val_arr in out strarray
              ) is
    lv_msg varchar2(4000 char);
  begin   
    merge into table_name t
    using ( select 
              ip_client_type_id as client_type_id,
              ip_client_type_cd as client_type_cd,
              ip_client_type_descr as client_type_descr,
              ip_status_cd as status_cd,
              ip_file_id as file_id
            from dual
          ) i
      on (t.client_type_id = i.client_type_id)
    when matched then 
     update
        set 
        t.client_type_cd = i.client_type_cd,
        t.client_type_descr = i.client_type_descr,
        t.status_cd = i.status_cd,
        t.file_id = i.file_id

     where    
        decode( t.client_type_cd , i.client_type_cd , 0 , 1 ) = 1 or
        decode( t.client_type_descr , i.client_type_descr , 0 , 1 ) = 1 or
        decode( t.status_cd , i.status_cd , 0 , 1 ) = 1 or
        decode( t.file_id , i.file_id , 0 , 1 ) = 1 


    when not matched then    
      insert (t.client_type_id, t.client_type_cd, t.client_type_descr, t.status_cd, t.file_id)
      values (i.client_type_id, i.client_type_cd, i.client_type_descr, i.status_cd, i.file_id);

    if sql%rowcount=1 then      
      select
        'Client type with ID = '||rpad(to_char(l.client_type_id||','),10,' ')||'Name = '||rpad(l.client_type_cd,30,' ')||' has got status = '||l.status_cd as msg
      into lv_msg
      from table_name l 
      where l.client_type_id = ip_client_type_id;
 
      dbms_output.put_line(lv_msg);
    end if;

    op_ins_val_arr.extend;
    op_ins_val_arr(op_ins_val_arr.last):=ip_client_type_id;
  end p_Ins;
  --
  procedure p_del(ip_ins_val_arr in strarray)
  is
    la_del_arr strarray:=strarray();
    la_msg_arr strarray:=strarray();
  begin    
      select 
        l.client_type_id,
        'Client type with ID = '||rpad(to_char(l.client_type_id||','),10,' ')||'Name = '||rpad(l.client_type_cd,30,' ')||' has got status = D via Delete' as msg
      bulk collect into la_del_arr, la_msg_arr
      from table_name l
      left join (select column_value as client_type_id from table(ip_ins_val_arr))m
        on (l.client_type_id = m.client_type_id)
      where m.client_type_id is null 
        and l.status_cd != 'D'
      ;
    
    forall i in 1..la_del_arr.count
      update table_name t 
        set t.status_cd = 'D'
      where t.client_type_id = la_del_arr(i)
    ;
    
    for i in 1..la_msg_arr.count loop
      dbms_output.put_line(la_msg_arr(i));
    end loop;
    
  end p_del;

begin
  
p_Ins(1,        'x',          'xx',          'A',      1,        v_ins_val_arr);
-------- R9 end

p_del(v_ins_val_arr);

commit;
end;
/
