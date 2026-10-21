// 门诊 AI 助手 API
// 说明：SSE 流式接口不走 ruoyi 的 axios 封装，用 fetch + Authorization 手动处理
import { getToken } from '@/utils/auth'

const BASE = '/agent-api'

/**
 * 流式对话。回调式 API：
 *   onEvent({event, data})
 * 事件类型：session / intent / token / card / citation / done
 */
export function streamChat({ sessionId, message, onEvent, onError }) {
  const token = getToken()
  const controller = new AbortController()

  fetch(`${BASE}/chat/stream`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': token ? `Bearer ${token}` : ''
    },
    body: JSON.stringify({ session_id: sessionId, message }),
    signal: controller.signal
  }).then(async (resp) => {
    if (!resp.ok) {
      const text = await resp.text()
      onError && onError(new Error(`HTTP ${resp.status}: ${text}`))
      return
    }
    const reader = resp.body.getReader()
    const decoder = new TextDecoder('utf-8')
    let buffer = ''

    // SSE 解析：以空行分隔事件块
    while (true) {
      const { done, value } = await reader.read()
      if (done) break
      buffer += decoder.decode(value, { stream: true })

      let idx
      while ((idx = buffer.indexOf('\n\n')) >= 0) {
        const raw = buffer.slice(0, idx)
        buffer = buffer.slice(idx + 2)

        let evName = 'message'
        let dataStr = ''
        for (const line of raw.split('\n')) {
          if (line.startsWith('event:')) {
            evName = line.slice(6).trim()
          } else if (line.startsWith('data:')) {
            dataStr += line.slice(5).trim()
          }
        }
        if (!dataStr) continue
        try {
          const data = JSON.parse(dataStr)
          onEvent && onEvent({ event: evName, data })
        } catch (e) {
          console.warn('SSE parse error:', e, dataStr)
        }
      }
    }
  }).catch((e) => {
    if (e.name !== 'AbortError') onError && onError(e)
  })

  // 返回 abort 控制器，供取消请求
  return controller
}

/**
 * 非流式对话（调试用）
 */
export async function chatOnce({ sessionId, message }) {
  const token = getToken()
  const resp = await fetch(`${BASE}/chat`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': token ? `Bearer ${token}` : ''
    },
    body: JSON.stringify({ session_id: sessionId, message })
  })
  return resp.json()
}

/**
 * Agent 健康检查
 */
export async function health() {
  const resp = await fetch(`${BASE}/health`)
  return resp.json()
}