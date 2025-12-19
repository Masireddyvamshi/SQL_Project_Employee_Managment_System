create database Employee_Managment_System;
use Employee_Managment_System;

CREATE TABLE JobDepartment (
    JobID INT PRIMARY KEY,
    jobdept VARCHAR(50),
    name VARCHAR(100),
    description TEXT,
    salaryrange VARCHAR(50)
);
select * from jobdepartment;

-- Table 2: Salary/Bonus
CREATE TABLE SalaryBonus (
    salaryID INT PRIMARY KEY,
    JobID INT,
    amount DECIMAL(10,2),
    annual DECIMAL(10,2),
    bonus DECIMAL(10,2),
    CONSTRAINT fk_salary_job FOREIGN KEY (jobID) REFERENCES JobDepartment(JobID)
        ON DELETE CASCADE ON UPDATE CASCADE
);
select * from salarybonus;
-- Table 3: Employee
CREATE TABLE Employee (
    empID INT PRIMARY KEY,
    firstname VARCHAR(50),
    lastname VARCHAR(50),
    gender VARCHAR(10),
    age INT,
    contactadd VARCHAR(100),
    empemail VARCHAR(100) UNIQUE,
    emppass VARCHAR(50),
    JobID INT,
    CONSTRAINT fk_employee_job FOREIGN KEY (JobID)
        REFERENCES JobDepartment(JobID)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);
select * from employee;

-- Table 4: Qualification
CREATE TABLE Qualification (
    QualID INT PRIMARY KEY,
    EmpID INT,
    Position VARCHAR(50),
    Requirements VARCHAR(255),
    Date_In DATE,
    CONSTRAINT fk_qualification_emp FOREIGN KEY (EmpID)
        REFERENCES Employee(empID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
select * from qualification;

-- Table 5: Leaves
CREATE TABLE Leaves (
    leaveID INT PRIMARY KEY,
    empID INT,
    date DATE,
    reason TEXT,
    CONSTRAINT fk_leave_emp FOREIGN KEY (empID) REFERENCES Employee(empID)
        ON DELETE CASCADE ON UPDATE CASCADE
);
select * from leaves;

-- Table 6: Payroll
CREATE TABLE Payroll (
    payrollID INT PRIMARY KEY,
    empID INT,
    jobID INT,
    salaryID INT,
    leaveID INT,
    date DATE,
    report TEXT,
    total_amount DECIMAL(10,2),
    CONSTRAINT fk_payroll_emp FOREIGN KEY (empID) REFERENCES Employee(empID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_job FOREIGN KEY (jobID) REFERENCES JobDepartment(jobID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_salary FOREIGN KEY (salaryID) REFERENCES SalaryBonus(salaryID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_leave FOREIGN KEY (leaveID) REFERENCES Leaves(leaveID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- I. EMPLOYEE INSIGHTS
-- How many unique employees are currently in the system?
select count(*)  as No_of_unique_employees
from employee;
-- empID is the PRIMARY KEY, every employee is already unique-- 

-- 2.Which departments have the highest number of employees?-- 
SELECT jd.jobdept, COUNT(e.empID) AS No_of_employees
FROM employee e
JOIN jobdepartment jd
    ON e.JobID = jd.JobID
GROUP BY jd.jobdept
HAVING COUNT(e.empID) = (
    SELECT MAX(dept_cnt)
    FROM (
        SELECT COUNT(e2.empID) AS dept_cnt
        FROM employee e2
        JOIN jobdepartment jd2
            ON e2.JobID = jd2.JobID
        GROUP BY jd2.jobdept
    ) as t
);

-- 3.What is the average salary per department?
select  jd.jobdept as Department,round(avg(sb.annual),2) as average_salary
from jobdepartment as jd
left join salarybonus as sb
on jd.JobID=sb.JobID
group by jd.jobdept
order by average_salary desc;

 
 
-- 4.Who are the top 5 highest-paid employees--
select e.empId,e.firstname,e.lastname,p.totalamount as Salary
from employee as e
inner join 
payroll as p
on e.empID=p.EmpID
order by Salary  desc
limit 5;

-- 5.What is the total salary expenditure across the company?
 select round(sum(totalamount),2) as Total_Salary_Expenditure
 from payroll;
 
 
-- II. JOB ROLE AND DEPARTMENT ANALYSIS
-- 1.How many different job roles exist in each department?
select jobdept as Departments ,count(distinct name ) as No_of_Job_Roles
from jobdepartment
group by jobdept
order by No_of_JOb_Roles desc; 


-- 2.What is the average salary range per department?
select jd.jobdept as department,round(avg(sb.amount),2) as average_salary
from jobdepartment as jd
left join salarybonus as sb
on jd.JobID=sb.JobID
group by jd.jobdept
order by average_salary desc;


-- 3.Which job roles offer the highest salary?
SELECT jd.name, sb.annual AS salary
FROM jobdepartment jd
JOIN salarybonus sb
    ON jd.JobID = sb.JobID
WHERE sb.annual = (
    SELECT MAX(annual)
    FROM salarybonus
); 


-- 4.Which departments have the highest total salary allocation?
select jd.jobdept as department,sum(sb.annual) as Total_Salary_Allocation
from jobdepartment as jd
join salarybonus as sb
on jd.JobID=sb.JobID
group by jd.jobdept
having sum(sb.annual)=(
select max(total_salary)
from 
(select sum(sb2.annual) as total_salary
from salarybonus as sb2
join jobdepartment as jd2
on sb2.jobId=jd2.jobId
group by jd2.jobdept) as t);



-- III. QUALIFICATION AND SKILLS ANALYSIS
-- 1.How many employees have at least one qualification listed?
select count(*) as employees_with_qualification
from qualification;

-- 2.Which positions require the most qualifications?
select position,count(QualID) as No_Of_Qualifications
from qualification
group by Position
having count(QualID)=(
select max(cnt)
from (
select count(QualID) as cnt
from qualification
group by Position) as t);


-- 3.Which employees have the highest number of qualifications
select e.empID,e.firstname,e.lastname,count(q.QualID) as No_Of_Qualifications
from employee as e 
join qualification as q
on e.empID=q.empID
group by e.empID,e.firstname,e.lastname
having count(q.QualID)=(
select max(cnt) 
from (select count(q.QualID) as cnt
from employee as e 
join qualification as q
on e.empID=q.empID
group by e.empID)as t);



-- IV. LEAVE AND ABSENCE PATTERNS
-- 1.Which year had the most employees taking leaves
select year(date),count(LeaveID ) as no_of_leaves from Leaves
group by year(date) 
HAVING COUNT(leaveID) = (
    SELECT MAX(cnt)
    FROM (
        SELECT COUNT(leaveID) AS cnt
        FROM Leaves
        GROUP BY YEAR(date)
    ) t
); 



-- 2.What is the average number of leave days taken by its employees per department?
SELECT 
    jd.jobdept AS department,
    ROUND(AVG(emp_leave_count), 2) AS avg_leave_days
FROM (
    SELECT 
        e.empID,
        e.JobID,
        COUNT(l.leaveID) AS emp_leave_count
    FROM employee e
    LEFT JOIN leaves l
        ON e.empID = l.empID
    GROUP BY e.empID, e.JobID
) t
JOIN jobdepartment jd
    ON t.JobID = jd.JobID
GROUP BY jd.jobdept; 

-- 3.Which employees have taken the most leaves 
select e.EmpID,e.firstname,e.lastname,count(l.LeaveId) as No_Of_Leaves
from employee as e
join leaves as l
on e.empID=l.EmpID
group by e.EmpID,e.firstname,e.lastname
having count(l.LeaveID)=(
select max(cnt) from (
select e.EmpID,e.firstname,e.lastname,count(l.LeaveId) as cnt
from employee as e
join leaves as l
on e.empID=l.EmpID
group by e.EmpID,e.firstname,e.lastname
) as t);

-- 4.What is the total number of leave days taken company-wide?
select count(LeaveID) as Total_Number_Of_LeaveDays_Taken_By_Company_wide
from leaves;

-- 5.How do leave days correlate with payroll amounts?
SELECT 
    e.empID,
    e.firstname,
    e.lastname,
    COUNT(l.leaveID) AS leave_days,
    SUM(p.totalamount) AS payroll_amount
FROM employee e
LEFT JOIN leaves l
    ON e.empID = l.empID
LEFT JOIN payroll p
    ON e.empID = p.empID
GROUP BY e.empID, e.firstname, e.lastname
order by payroll_amount desc;

-- V. PAYROLL AND COMPENSATION ANALYSIS
-- 1.What is the total monthly payroll processed?
SELECT 
    YEAR(date) AS payroll_year,
    MONTH(date) AS payroll_month,
    SUM(totalamount) AS total_monthly_payroll
FROM payroll
GROUP BY YEAR(date), MONTH(date)
ORDER BY payroll_year, payroll_month;

-- 2.What is the average bonus given per department
select jd.jobdept,round(avg(sb.bonus),2) as average_bonus 
from jobdepartment as jd
join salarybonus as sb
on jd.JobID=sb.JobID
group by jd.jobdept
order by average_bonus desc;

-- 3.Which department receives the highest total bonuses
SELECT 
    jd.jobdept,
    SUM(sb.bonus) AS total_bonus
FROM jobdepartment jd
JOIN salarybonus sb
    ON jd.JobID = sb.JobID
GROUP BY jd.jobdept
HAVING SUM(sb.bonus) = (
    SELECT MAX(total_bonus)
    FROM (
        SELECT SUM(bonus) AS total_bonus
        FROM salarybonus sb2
        JOIN jobdepartment jd2
            ON sb2.JobID = jd2.JobID
        GROUP BY jd2.jobdept
    ) t
);

-- 4.What is the average value of total_amount after considering leave deductions
select avg(totalamount) as average_total_amount_after_leavedeductions
from payroll;




 