/*ADDING FILE TO VERTICA*/
CREATE TABLE public.sg_rgs_pass_license
(
phone_md5 varchar(255),
first_name_md5 varchar(255),
last_name_md5 varchar(255),
patronymic_name_md5 varchar(255),
login varchar(255),
user_id int,
PassportNumber varchar(255),
license varchar(255)
)

COPY public.sg_rgs_pass_license
FROM local 'C:/Users/sgulbin/Work/_Выгрузки_и_Расчеты/rgs_w_passp_license_v2.csv'
PARSER FCSVPARSER (header = 'true')
DIRECT
ABORT ON ERROR

CREATE TABLE public.sg_rgs_pass_license_unhashed AS

WITH pricing AS
(SELECT
	user_id 
	, Pricing_coefficient 
	, DrivingStyle_coefficient
	, DrivingStyle_preScore 
FROM DMA.delimobil_user_coefficient_pricing ducp
where status = 'active')
SELECT
	rgs.user_id
	, rgs.login
	, du.first_name 
	, du.last_name 
	, du.patronymic_name 
	, pn.PassportNumber
	, aul.License
	, p.DrivingStyle_preScore
FROM public.sg_rgs_pass_license rgs
LEFT JOIN CDDS.A_User_PassportNumber pn on pn.User_id = rgs.user_id
LEFT JOIN DMA.delimobil_user du on du.user_id = rgs.user_id
LEFT JOIN CDDS.A_User_License aul on aul.User_id = rgs.user_id
LEFT JOIN pricing p on p.user_id = rgs.user_id
