/*01 – DATA IMPORT*/
PROC IMPORT DATAFILE="/home/u64017309/lending_club_loans.csv"
    OUT=work.loans
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
RUN;


/* 02 – DATA CLEANING & FEATURE CREATION*/
DATA loans_clean;
    SET work.loans;

    /* 1 = loan not fully paid, 0 = fully paid */
    default_flag = not.fully.paid;
RUN;



/*03 – EXPLORATORY DATA ANALYSIS*/
PROC CONTENTS DATA=loans_clean;
RUN;

PROC MEANS DATA=loans_clean N MEAN STD MIN MAX;
    VAR 'int.rate'n installment 'log.annual.inc'n dti fico 'revol.bal'n 'revol.util'n;
RUN;


PROC FREQ DATA=loans_clean;
    TABLES purpose 'credit.policy'n default_flag;
RUN;



/*04 – DEFAULT RATE ANALYSIS-Shows how risk differs between borrowers meeting vs. not meeting credit policy*/
PROC SQL;
    SELECT 
        'credit.policy'n,
        COUNT(*) AS total_loans,
        SUM(default_flag) AS defaulted_loans,
        (SUM(default_flag)/COUNT(*))*100 AS default_rate_pct
    FROM loans_clean
    GROUP BY 'credit.policy'n
    ORDER BY default_rate_pct DESC;
QUIT;


/*Analyzes which loan purposes (car, credit card, debt consolidation, etc.) are riskier*/
PROC SQL;
    SELECT 
        purpose,
        COUNT(*) AS total_loans,
        SUM(default_flag) AS defaulted_loans,
        (SUM(default_flag)/COUNT(*))*100 AS default_rate_pct
    FROM loans_clean
    GROUP BY purpose
    ORDER BY default_rate_pct DESC;
QUIT;

/*Groups borrowers by Debt-to-Income ratio (DTI) Helps segment risk by ability to pay*/
DATA loans_dti;
    SET loans_clean;

    IF dti < 10 THEN dti_bucket = "Low";
    ELSE IF dti <= 20 THEN dti_bucket = "Medium";
    ELSE IF dti <= 30 THEN dti_bucket = "High";
    ELSE dti_bucket = "Very High";
RUN;


/*Shows how default risk changes with DTI. High DTI → usually higher default risk*/
PROC SQL;
    SELECT
        dti_bucket,
        COUNT(*) AS total_loans,
        SUM(default_flag) AS defaulted_loans,
        (SUM(default_flag)/COUNT(*))*100 AS default_rate_pct
    FROM loans_dti
    GROUP BY dti_bucket
    ORDER BY default_rate_pct DESC;
QUIT;


/* 05 – LOGISTIC REGRESSION MODEL- models probability of loan not fully paid*/
PROC LOGISTIC DATA=loans_clean;
    MODEL default_flag(event='1') =
        'int.rate'n
        'log.annual.inc'n
        dti
        fico
        'revol.bal'n
        'revol.util'n
        'inq.last.6mths'n
        'delinq.2yrs'n
        'pub.rec'n;
RUN;



/*06 – VISUALIZATIONS- Visualizes default rate by DTI bucket*/
PROC SGPLOT DATA=loans_dti;
    VBAR dti_bucket / RESPONSE=default_flag STAT=MEAN;
    
    

    
    
 
    YAXIS LABEL="Default Rate (%)";
    XAXIS LABEL="DTI Bucket";
RUN;
