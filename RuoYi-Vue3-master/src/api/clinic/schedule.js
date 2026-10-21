import request from '@/utils/request'

export function listSchedule(query) {
  return request({ url: '/clinic/schedule/list', method: 'get', params: query })
}

export function getSchedule(scheduleId) {
  return request({ url: '/clinic/schedule/' + scheduleId, method: 'get' })
}

export function addSchedule(data) {
  return request({ url: '/clinic/schedule', method: 'post', data })
}

export function updateSchedule(data) {
  return request({ url: '/clinic/schedule', method: 'put', data })
}

export function delSchedule(scheduleId) {
  return request({ url: '/clinic/schedule/' + scheduleId, method: 'delete' })
}