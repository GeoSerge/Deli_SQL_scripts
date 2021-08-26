select DISTINCT usr.*
from dma.delimobil_rent rnt
left join cdds.A_Rent_ScoringFlex scr on rnt.rent_id = scr.Rent_id
left join dma.delimobil_user usr on usr.user_id = rnt.user_id
where rnt."Start" >= '2020-06-09' and COALESCE("preScore"['preScoreMemberList']['0']['score'], "coefficients"['0']['data']['preScoreMemberList']['1']['score']) is null

copy public.sg_users_w_kbm_error
FROM local 'C:\Users\sgulbin\Work\Analysis\DataQualityAnalysis\stage_2\KBM_cols_error_new_algo_short_format.csv' 
PARSER fcsvparser(header='true')
DIRECT
ABORT ON ERROR
REJECTED DATA 'C:\Users\sgulbin\Desktop\Rejections.txt'
EXCEPTIONS 'C:\Users\sgulbin\Desktop\Exceptions.txt'

select case when usnr.usersta
from dma.delimobil_user usr
left join cdds.T_User_UserStatus us on us.user_id = usr.user_id
left join cdds.A_UserStatus_NameRu usnr on usnr.UserStatus_id = us.UserStatus_id
left join cdds.A_User_PassportNumber pn on pn.User_id = usr.user_id
left join cdds.A_User_PassportDepartment pd on pd.User_id = usr.user_id
left join cdds.A_User_PassportIssueDate pid on pid.User_id = usr.user_id
left join cdds.A_User_PassportDepartmentCode pdc on pdc.User_id = usr.user_id
left join cdds.A_User_PassportBirthPlace pbp on pbp.User_id = usr.user_id
left join cdds.A_User_PassportRegistration pr on pr.User_id = usr.user_id
left join cdds.A_User_LicenseCategory lc on lc.User_id = usr.user_id
left join cdds.A_User_License l on l.User_id = usr.user_id
left join cdds.A_User_LicenseStartDate lstartd on lstartd.User_id = usr.user_id
left join cdds.A_User_LicenseExpireDate led on led.User_id = usr.user_id
left join cdds.A_User_LicenseSetDate lsetd on lsetd.User_id = usr.user_id
where usr.activation_dtime is not null and us.UserStatus_id in (250002,250001,250005,250004)

select * from cdds.T_User_UserStatus

select json.*
from dma.delimobil_user usr
left join cdds.A_User_PassportJSON json on json.user_id = usr.user_id
where usr.registration_dtime > '2020-07-01' and json.PassportJSON is not null
