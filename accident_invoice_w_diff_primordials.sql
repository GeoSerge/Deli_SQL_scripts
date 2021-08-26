/* OBSERVING ACCIDENT PENALTIES  */
select dic.user_id, dic.invoice_id_first, dic.invoice_id_primordial, dic.amount, dic.status, dic.first_creation, dic.last_creation, dic.last_process, dic.*
from DMA.delimobil_invoice_current dic 
where penalty_type = 'accident' and user_id = 19503055
order by dic.user_id, dic.first_creation