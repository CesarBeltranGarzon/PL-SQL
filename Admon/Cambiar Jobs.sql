begin
  -- Cambia el WHAT enviando el no de Job y el WHAT que debe quedar
  sys.dbms_ijob.what(job => :job,
                     what => '');
end;
