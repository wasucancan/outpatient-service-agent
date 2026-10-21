import request from '@/utils/request'
export function listDrugBatch(q) { return request({url:'/clinic/drugbatch/list',method:'get',params:q}) }
export function getDrugBatch(id) { return request({url:'/clinic/drugbatch/'+id,method:'get'}) }
export function addDrugBatch(data) { return request({url:'/clinic/drugbatch',method:'post',data}) }
export function updateDrugBatch(data) { return request({url:'/clinic/drugbatch',method:'put',data}) }
export function delDrugBatch(ids) { return request({url:'/clinic/drugbatch/'+ids,method:'delete'}) }
export function listExpiring() { return request({url:'/clinic/drugbatch/expiring',method:'get',params:{pageNum:1,pageSize:50}}) }