import request from '@/utils/request'
export function listAppointment(q) { return request({url:'/clinic/appointment/list',method:'get',params:q}) }
export function getAppointment(id) { return request({url:'/clinic/appointment/'+id,method:'get'}) }
export function cancelAppointment(id,reason) { return request({url:'/clinic/appointment/cancel/'+id,method:'post',data:{reason:reason||'后台取消'}}) }
export function delAppointment(ids) { return request({url:'/clinic/appointment/'+ids,method:'delete'}) }