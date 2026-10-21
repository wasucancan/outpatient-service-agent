import request from '@/utils/request'

// 查询用户-患者绑定列表
export function listBind(query) {
  return request({ url: '/clinic/bind/list', method: 'get', params: query })
}

// 查询绑定详情
export function getBind(bindId) {
  return request({ url: '/clinic/bind/' + bindId, method: 'get' })
}

// 新增绑定
export function addBind(data) {
  return request({ url: '/clinic/bind', method: 'post', data })
}

// 修改绑定
export function updateBind(data) {
  return request({ url: '/clinic/bind', method: 'put', data })
}

// 删除绑定
export function delBind(bindId) {
  return request({ url: '/clinic/bind/' + bindId, method: 'delete' })
}

// 查询当前登录用户绑定
export function myBind() {
  return request({ url: '/clinic/bind/me', method: 'get' })
}