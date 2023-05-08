SELECT DISTINCT 
    dp.dir_uid AS username,
    de.mail AS email,
    CASE 
        WHEN dp.primaryaffiliation = 'Student' THEN 'Student'  
        WHEN dp.primaryaffiliation = 'Faculty' THEN 
            CASE
                WHEN daf.edupersonaffiliation = 'Faculty' 
                    AND daf.description = 'Student Faculty' THEN 'Student'
                ELSE 'Faculty/Staff' 
        END
        WHEN dp.primaryaffiliation = 'Staff' THEN 'Faculty/Staff' 
        WHEN dp.primaryaffiliation = 'Employee' THEN
            CASE
                WHEN daf.edupersonaffiliation = 'Employee' 
                    AND daf.description IN ('Student Employee', 'Student Faculty') THEN 'Student' 
                ELSE 'Faculty/Staff'
            END
        WHEN dp.primaryaffiliation = 'Officer/Professional' THEN 'Faculty/Staff'
        WHEN dp.primaryaffiliation = 'Affiliate'
            AND daf.edupersonaffiliation = 'Affiliate'
            AND daf.description IN ('Student Employee', 'Continuing Ed Non-Credit Student') THEN 'Student'
        WHEN dp.primaryaffiliation = 'Member'
            AND daf.edupersonaffiliation = 'Member'
            AND daf.description = 'Faculty' THEN 'Faculty/Staff'
        ELSE 'Student'
    END AS person_type
FROM dirsvcs.dir_person dp 
    INNER JOIN dirsvcs.dir_affiliation daf
        ON daf.uuid = dp.uuid
            AND daf.campus = 'Boulder Campus' 
            AND dp.primaryaffiliation NOT IN ('Not currently affiliated', 'Retiree', 'Affiliate', 'Member')
            AND daf.description NOT IN (
                'Admitted Student', 'Alum', 'Confirmed Student', 'Former Student', 'Member Spouse', 
                'Sponsored', 'Sponsored EFL', 'Retiree', 'Boulder3'
            )
            AND daf.description NOT LIKE 'POI_%'
    LEFT JOIN dirsvcs.dir_email de
        ON de.uuid = dp.uuid
            AND de.mail_flag = 'M'
            AND de.mail IS NOT NULL
WHERE (
    dp.primaryaffiliation != 'Student'
        AND LOWER(de.mail) not like '%cu.edu'
    ) OR (
    dp.primaryaffiliation = 'Student'
        AND EXISTS (
            SELECT 'x' FROM dirsvcs.dir_acad_career WHERE uuid = dp.uuid
        )
    )
    AND de.mail IS NOT NULL
    AND LOWER(de.mail) NOT LIKE '%cu.edu';

/*This SQL script selects a username and email and creates a new column 
to classify people in a database under 'person_type' based on their primary 
affiliation, taken from the dir_person table, and their education affiliation
(edupersonaffiliation), taken from the dir_affiliation table. The person_type 
column is categorized into 'Student', 'Faculty/Staff', or 'Student/Faculty.' 
Certain conditions must be met in order for a user to be selected. For example, 
former students, retired faculty/staff, or spouses should not be selected. An 
inner join is performed on the dir_person and edupersonaffiliation tables. In 
addition, email addresses from dir_email are also selected, with a left join 
from the two previous tables to the dir_email table. If a user is not classified 
as a student, their email address should not end in cu.edu. If a user is a 
student, their id should be found in the dir_acad_career table.

Summary: This SQL script retrieves a distinct list of usernames, emails, and 
their associated person type for those affiliated with the CU Boulder Campus,
excluding certain types of affiliations and email addresses. 
*/