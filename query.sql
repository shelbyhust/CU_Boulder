SELECT DISTINCT 
    dp.dir_uid AS username,
    de.mail AS email,
    CASE 
        WHEN dp.primaryaffiliation = 'Student'
            AND EXISTS (
                SELECT 'x' FROM dirsvcs.dir_acad_career WHERE uuid = dp.uuid
            ) THEN 'Student'  
        WHEN dp.primaryaffiliation = 'Faculty' AND daf.edupersonaffiliation = 'Faculty' 
            CASE WHEN daf.description = 'Student Faculty' THEN 'Student'
                ELSE 'Faculty/Staff' 
            END
        WHEN dp.primaryaffiliation = 'Staff' THEN 'Faculty/Staff' 
        WHEN dp.primaryaffiliation = 'Employee' AND daf.edupersonaffiliation = 'Employee' 
            CASE WHEN daf.description IN ('Student Employee', 'Student Faculty') THEN 'Student' 
                ELSE 'Faculty/Staff'
            END
        WHEN dp.primaryaffiliation = 'Officer/Professional' THEN 'Faculty/Staff'
        WHEN daf.edupersonaffiliation = 'Affiliate'
            AND daf.description IN ('Student Employee', 'Continuing Ed Non-Credit Student') THEN 'Student'
        WHEN daf.edupersonaffiliation = 'Member'
            AND daf.description = 'Faculty' THEN 'Faculty/Staff'
        ELSE 'Student'
    END AS person_type
FROM dirsvcs.dir_person dp 
    INNER JOIN dirsvcs.dir_affiliation daf
        ON daf.uuid = dp.uuid
    LEFT JOIN dirsvcs.dir_email de
        ON de.uuid = dp.uuid
            AND de.mail IS NOT NULL
            AND de.mail_flag = 'M'
WHERE LOWER(de.mail) NOT LIKE '%cu.edu'
    AND daf.campus = 'Boulder Campus' 
    AND dp.primaryaffiliation NOT IN ('Not currently affiliated', 'Retiree', 'Affiliate', 'Member')
    AND daf.description NOT IN (
        'Admitted Student', 'Alum', 'Confirmed Student', 'Former Student', 'Member Spouse', 
        'Sponsored', 'Sponsored EFL', 'Retiree', 'Boulder3'
    )
    AND daf.description NOT LIKE 'POI_%'; --need to escape '_' if 'POI_' should be matched literally

/*This SQL script selects a username, email 'person_type' from three tables. 
The 'person_type' column is derived using 'CASE' statements based on a user's
primary affiliation, taken from the dir_person table, and their education 
affiliation (edupersonaffiliation), taken from the dir_affiliation table. 
The person_type column is categorized into 'Student' or 'Faculty/Staff.'
Certain conditions must be met in order for a user to be selected. For example, 
former students, retired faculty/staff, or spouses should not be selected. If 
a user is a student, their id should be found in the dir_acad_career table. An 
inner join is performed on the dir_person and edupersonaffiliation tables. In 
addition, email addresses from dir_email are also selected, with a left join 
from the two previous tables to the dir_email table. 

Summary: This SQL script retrieves a distinct list of usernames, emails, and 
their associated person type for those affiliated with the CU Boulder Campus,
excluding certain types of affiliations and email addresses. 
*/