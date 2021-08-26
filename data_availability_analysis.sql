-- SELECTING USERS WITH NO DATA
select usr.user_id
	   ,usr.registration_dtime
	   ,usr.activation_dtime
	   ,usr.first_name
	   ,usr.patronymic_name
	   ,usr.last_name
	   ,birth.PassportBirthPlace
	   ,nmbr.PassportNumber
	   ,reg.PassportRegistration
	   ,dep.PassportDepartment
	   ,dep_code.PassportDepartmentCode
	   ,iss.PassportIssueDate
	   ,lcns.License
	   ,cat.LicenseCategory
	   ,set.LicenseSetDate
	   ,start.LicenseStartDate
	   ,ss.createApplicant
	   ,ss.addDocument
	   ,(case when usr.first_name is null then TRUE else FALSE end) as first_name_NA
	   ,(case when usr.patronymic_name is null then TRUE else FALSE end) as patronymic_name_NA
	   ,(case when usr.last_name is null then TRUE else FALSE end) as last_name_NA
	   ,(case when birth.PassportBirthPlace is null then TRUE else FALSE end) as birth_place_NA
	   ,(case when nmbr.PassportNumber is null then TRUE else FALSE end) as passport_number_NA
	   ,(case when reg.PassportRegistration is null then TRUE else FALSE end) as passport_registration_NA
	   ,(case when dep.PassportDepartment is null then TRUE else FALSE end) as passport_department_NA
	   ,(case when dep_code.PassportDepartmentCode is null then TRUE else FALSE end) as passport_department_code_NA
	   ,(case when iss.PassportIssueDate is null then TRUE else FALSE end) as passport_issue_date_NA
	   ,(case when lcns.License is null then TRUE else FALSE end) as license_number_NA
	   ,(case when cat.LicenseCategory is null then TRUE else FALSE end) as license_category_NA
	   ,(case when set.LicenseSetDate is null then TRUE else FALSE end) as license_set_date_NA
	   ,(case when start.LicenseStartDate is null then TRUE else FALSE end) as license_start_date_NA
from dma.delimobil_user usr
left join cdds.A_User_PassportBirthPlace birth on birth.User_id = usr.user_id -- birth place
left join cdds.A_User_PassportNumber nmbr on nmbr.User_id = usr.user_id -- passport number
left join cdds.A_User_PassportRegistration reg on reg.User_id = usr.user_id -- passport registration
left join cdds.A_User_PassportDepartment dep on dep.user_id = usr.user_id -- passport department
left join cdds.A_User_PassportDepartmentCode dep_code on dep_code.user_id = usr.user_id -- passport department code
left join cdds.A_User_PassportIssueDate iss on iss.User_id = usr.user_id -- passport issue date
left join cdds.A_User_License lcns on lcns.User_id = usr.user_id -- license number
left join cdds.A_User_LicenseCategory cat on cat.user_id = usr.user_id -- license category
left join cdds.A_User_LicenseSetDate set on set.User_id = usr.user_id -- license set date
left join cdds.A_User_LicenseStartDate start on start.User_id = usr.user_id -- license start date
left join (
select client_id
	   , SUM(case when op = 'createApplicant' THEN 1 ELSE 0 END) as createApplicant
	   , SUM(case when op = 'addDocument' THEN 1 ELSE 0 END) as addDocument
from saeo.sumsub_history
group by client_id
having SUM(case when op = 'addDocument' THEN 1 ELSE 0 END) > 3) ss on ss.client_id = usr.user_ext
where usr.activation_dtime is not null
	  and usr.last_ride >= '2020-06-09'
	  and (usr.first_name is null
	  	   or usr.patronymic_name is null 
	  	   or usr.last_name is null 
	  	   or birth.PassportBirthPlace is null 
	  	   or nmbr.PassportNumber is null
	  	   or reg.PassportRegistration is null
	  	   or dep.PassportDepartment is null
	  	   or dep_code.PassportDepartmentCode is null
	  	   or iss.PassportIssueDate is null
	  	   or lcns.License is null
	  	   or cat.LicenseCategory is null
	  	   or set.LicenseSetDate is null
	  	   or start.LicenseStartDate is null)