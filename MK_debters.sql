create table public.sg_MK_debters (
company varchar(255)
,legal_form varchar(255)
,passport_number varchar(255)
,first_name varchar(255)
,patronymic_name varchar(255)
,last_name varchar(255))

drop table public.sg_MK_defaulters

copy public.sg_MK_debters
FROM local 'C:\Users\sgulbin\Work\MicroCapital_должники\MK_debters.csv' 
PARSER fcsvparser(header='true')
DIRECT
ABORT ON ERROR
REJECTED DATA 'C:\Users\sgulbin\Desktop\Rejections.txt'
EXCEPTIONS 'C:\Users\sgulbin\Desktop\Exceptions.txt'

select *
from public.sg_MK_debters
where passport_number = '9201 466268'

select *
from dds.A_User_PassportNumber
where RIGHT(PassportNumber,6) = '466268'

select psp.*, usr.*
from dma.delimobil_user usr
left join dds.A_User_PassportNumber psp on psp.user_id = usr.user_id
where last_name = 'Медведев' and first_name = 'Михаил' and patronymic_name = 'Олегович'

select count(DISTINCT(psp.user_id))
from public.sg_MK_debters debt
left join dds.A_User_PassportNumber psp on psp.PassportNumber = debt.passport_number
where psp.User_id is not null

with invoices as
(select user_id
	   , sum(case when status = 'success' then amount else 0 end) paid_invoices
	   , sum(case when status <> 'success' then amount else 0 end) not_paid_invoices
	   , sum(case when status = 'success' then amount else 0 end)/sum(amount) as share_of_paid
from dma.delimobil_invoice_current
where first_creation >= '2019-01-01' and amount > 2
group by user_id)
select psp.User_id, debt.*, invoices.*
from public.sg_MK_debters debt
left join dds.A_User_PassportNumber psp on psp.PassportNumber = debt.passport_number
left join invoices on invoices.user_id = psp.User_id
where psp.User_id is not null and invoices.user_id is not null
order by invoices.not_paid_invoices desc