MERGE INTO bonuses b
USING (
  SELECT employee_id, salary, dept_no
  FROM employee
  WHERE dept_no =20
      ) e
ON (b.employee_id = e.employee_id)
WHEN MATCHED THEN
  UPDATE SET b.bonus = e.salary * 0.1
  DELETE WHERE (e.salary < 40000)
WHEN NOT MATCHED THEN
  INSERT (b.employee_id, b.bonus)
  VALUES (e.employee_id, e.salary * 0.05)
  WHERE (e.salary > 40000);
