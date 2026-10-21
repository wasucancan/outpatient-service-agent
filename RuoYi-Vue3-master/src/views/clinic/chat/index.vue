<template>
  <div class="clinic-chat">
    <!-- 顶部工具条 -->
    <div class="chat-header">
      <div class="title">
        <svg-icon icon-class="message" /> 青枫门诊 · AI 就诊助手
        <el-tag size="small" :type="agentOk ? 'success' : 'danger'" style="margin-left: 12px;">
          {{ agentOk ? 'Agent 在线' : 'Agent 离线' }}
        </el-tag>
      </div>
      <div>
        <el-button size="small" @click="onNewSession">新会话</el-button>
        <el-button size="small" @click="onClear">清屏</el-button>
      </div>
    </div>

    <!-- 消息列表 -->
    <div ref="listRef" class="chat-list">
      <div v-if="messages.length === 0" class="empty">
        <p>👋 我是青枫门诊 AI 就诊助手，可以帮您：</p>
        <ul>
          <li>💬 咨询就诊流程、挂号规则、医保材料</li>
          <li>📅 查询医生号源、余号</li>
          <li>📋 查询本人预约单</li>
          <li>✅ 智能挂号（先预览后确认）</li>
          <li>❌ 取消本人预约（先预览后确认）</li>
        </ul>
        <p class="hint">⚠️ 我不能进行疾病诊断、推荐药物、解读报告</p>
      </div>

      <div
        v-for="(m, i) in messages"
        :key="i"
        :class="['msg', m.role]"
      >
        <div class="avatar">{{ m.role === 'user' ? '我' : 'AI' }}</div>
        <div class="bubble">
          <div class="text" v-html="renderText(m.content)"></div>

          <!-- 卡片区域 -->
          <div v-if="m.card" class="card-area">
            <!-- 排班列表 -->
            <div v-if="m.card.type === 'schedule_list'" class="card schedule-list">
              <div class="card-title">📅 实时排班（共 {{ m.card.data.length }} 条）</div>
              <el-table :data="m.card.data" size="small" border>
                <el-table-column prop="scheduleId" label="排班ID" width="90" />
                <el-table-column prop="departmentId" label="科室" width="70" />
                <el-table-column prop="doctorId" label="医生" width="70" />
                <el-table-column prop="visitDate" label="日期" width="110" />
                <el-table-column prop="period" label="时段" width="70" />
                <el-table-column label="时间" width="140">
                  <template #default="{ row }">{{ row.startTime }}-{{ row.endTime }}</template>
                </el-table-column>
                <el-table-column label="余号" width="80">
                  <template #default="{ row }">
                    <el-tag :type="row.remainingQuota > 0 ? 'success' : 'danger'" size="small">
                      {{ row.remainingQuota }}/{{ row.totalQuota }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column label="操作">
                  <template #default="{ row }">
                    <el-button
                      size="small"
                      type="primary"
                      :disabled="row.remainingQuota <= 0"
                      @click="onBookSchedule(row.scheduleId)"
                    >挂号</el-button>
                  </template>
                </el-table-column>
              </el-table>
            </div>

            <!-- 挂号预览 -->
            <div v-else-if="m.card.type === 'book_preview'" class="card book-preview">
              <div class="card-title">✅ 挂号预览（确认后才创建）</div>
              <div class="kv">
                <div><span>患者ID</span><b>{{ m.card.data.patientId }}</b></div>
                <div><span>排班</span><b>{{ m.card.data.scheduleId }}</b></div>
                <div><span>科室/医生</span><b>{{ m.card.data.departmentId }} / {{ m.card.data.doctorId }}</b></div>
                <div><span>就诊时间</span><b>{{ m.card.data.visitDate }} {{ m.card.data.period }} {{ m.card.data.startTime }}-{{ m.card.data.endTime }}</b></div>
                <div><span>实时余号</span><b>{{ m.card.data.remainingQuota }}</b></div>
              </div>
              <div class="actions">
                <el-button type="primary" size="small" @click="onQuickSend('确认')">确认挂号</el-button>
                <el-button size="small" @click="onQuickSend('取消')">放弃</el-button>
              </div>
            </div>

            <!-- 挂号凭证 -->
            <div v-else-if="m.card.type === 'appointment_voucher'" class="card voucher">
              <div class="card-title">🎫 取号凭证</div>
              <div class="voucher-no">{{ m.card.data.appointmentNo }}</div>
              <div class="kv">
                <div><span>预约ID</span><b>{{ m.card.data.appointmentId }}</b></div>
                <div><span>就诊时间</span><b>{{ m.card.data.visitDate }} {{ m.card.data.period }}</b></div>
                <div><span>科室/医生</span><b>{{ m.card.data.departmentId }} / {{ m.card.data.doctorId }}</b></div>
              </div>
              <div class="hint">请保存凭证号；就诊开始前 2 小时内不可取消。</div>
            </div>

            <!-- 取消预览 -->
            <div v-else-if="m.card.type === 'cancel_preview'" class="card cancel-preview">
              <div class="card-title">🗑 取消预览（确认后执行）</div>
              <div class="kv">
                <div><span>凭证号</span><b>{{ m.card.data.appointmentNo }}</b></div>
                <div><span>就诊时间</span><b>{{ m.card.data.visitDate }} {{ m.card.data.period }}</b></div>
                <div><span>状态</span><b>{{ m.card.data.status }}</b></div>
              </div>
              <div class="actions">
                <el-button type="danger" size="small" @click="onQuickSend('确认')">确认取消</el-button>
                <el-button size="small" @click="onQuickSend('放弃')">放弃</el-button>
              </div>
            </div>

            <!-- 本人预约列表 -->
            <div v-else-if="m.card.type === 'appointment_list'" class="card appt-list">
              <div class="card-title">📋 我的预约（{{ m.card.data.length }} 条）</div>
              <el-table :data="m.card.data" size="small" border>
                <el-table-column prop="appointmentNo" label="凭证号" width="180" />
                <el-table-column prop="visitDate" label="日期" width="110" />
                <el-table-column prop="period" label="时段" width="70" />
                <el-table-column prop="status" label="状态" width="100" />
                <el-table-column label="操作">
                  <template #default="{ row }">
                    <el-button size="small" type="danger" @click="onCancelAppt(row.appointmentNo)">取消</el-button>
                  </template>
                </el-table-column>
              </el-table>
            </div>
          </div>

          <!-- 引用 -->
          <div v-if="m.citations && m.citations.length" class="citations">
            <el-tag
              v-for="c in m.citations"
              :key="c.chunk_id"
              size="small"
              type="info"
              effect="plain"
              style="margin: 2px;"
            >📖 {{ c.chunk_id }} · {{ c.title }}</el-tag>
          </div>
        </div>
      </div>
    </div>

    <!-- 输入区 -->
    <div class="chat-input">
      <el-input
        v-model="input"
        type="textarea"
        :rows="2"
        placeholder="试着问：初诊就诊流程是什么 / 明天内科号源 / 我要挂号排班5001 / 查我的预约"
        :disabled="sending"
        @keydown.enter.prevent="onSend"
      />
      <el-button
        type="primary"
        :loading="sending"
        :disabled="!input.trim()"
        style="margin-left: 12px; height: 60px;"
        @click="onSend"
      >{{ sending ? '生成中...' : '发送' }}</el-button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick, onBeforeUnmount } from 'vue'
import { ElMessage } from 'element-plus'
import { streamChat, health } from '@/api/clinic/chat'

const messages = ref([])
const input = ref('')
const sending = ref(false)
const agentOk = ref(false)
const sessionId = ref(null)
const listRef = ref(null)
let abortCtrl = null

onMounted(async () => {
  try {
    const h = await health()
    agentOk.value = h.status === 'ok'
  } catch (e) {
    agentOk.value = false
  }
})

onBeforeUnmount(() => {
  if (abortCtrl) abortCtrl.abort()
})

function renderText(t) {
  if (!t) return ''
  // 简单处理：换行转 <br>，不做 markdown
  return t.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/\n/g, '<br>')
}

function scrollToBottom() {
  nextTick(() => {
    if (listRef.value) listRef.value.scrollTop = listRef.value.scrollHeight
  })
}

function pushMessage(role, content, extra = {}) {
  messages.value.push({ role, content, card: null, citations: [], ...extra })
  scrollToBottom()
}

function onNewSession() {
  sessionId.value = null
  ElMessage.success('已开启新会话')
}

function onClear() {
  messages.value = []
}

function onQuickSend(text) {
  input.value = text
  onSend()
}

function onBookSchedule(scheduleId) {
  input.value = `我要挂号排班${scheduleId}`
  onSend()
}

function onCancelAppt(appointmentNo) {
  input.value = `取消预约单 ${appointmentNo}`
  onSend()
}

function onSend() {
  const msg = input.value.trim()
  if (!msg || sending.value) return

  pushMessage('user', msg)
  input.value = ''
  sending.value = true

  const assistantMsg = { role: 'assistant', content: '', card: null, citations: [] }
  messages.value.push(assistantMsg)
  const idx = messages.value.length - 1
  scrollToBottom()

  abortCtrl = streamChat({
    sessionId: sessionId.value,
    message: msg,
    onEvent: ({ event, data }) => {
      switch (event) {
        case 'session':
          sessionId.value = data.session_id
          break
        case 'token':
          messages.value[idx].content += data.content || ''
          scrollToBottom()
          break
        case 'card':
          messages.value[idx].card = data
          // 挂号凭证 → 遍历历史排班卡片，对应排班余号 -1
          if (data.type === 'appointment_voucher' && data.data && data.data.scheduleId) {
            const targetSid = Number(data.data.scheduleId)
            for (const m of messages.value) {
              if (m.card && m.card.type === 'schedule_list' && Array.isArray(m.card.data)) {
                for (const row of m.card.data) {
                  if (Number(row.scheduleId) === targetSid && row.remainingQuota > 0) {
                    row.remainingQuota -= 1
                  }
                }
              }
            }
          }
          scrollToBottom()
          break
        case 'citation':
          messages.value[idx].citations = data.items || []
          break
        case 'done':
          sending.value = false
          break
        case 'intent':
          messages.value[idx].intent = data.intent
          messages.value[idx].blocked = data.blocked
          break
        default:
          break
      }
    },
    onError: (e) => {
      messages.value[idx].content = `请求失败：${e.message}`
      sending.value = false
    }
  })
}
</script>

<style scoped lang="scss">
.clinic-chat {
  display: flex;
  flex-direction: column;
  height: calc(100vh - 84px);
  padding: 16px;
  background: #f5f7fa;

  .chat-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 8px 16px;
    background: #fff;
    border-radius: 8px;
    margin-bottom: 12px;
    box-shadow: 0 1px 4px rgba(0,0,0,0.06);

    .title {
      font-size: 16px;
      font-weight: 600;
      display: flex;
      align-items: center;
      gap: 6px;
    }
  }

  .chat-list {
    flex: 1;
    overflow-y: auto;
    padding: 12px;
    background: #fff;
    border-radius: 8px;
    box-shadow: 0 1px 4px rgba(0,0,0,0.06);

    .empty {
      color: #909399;
      padding: 40px 20px;
      text-align: center;
      ul { display: inline-block; text-align: left; margin: 8px 0; }
      li { list-style: none; padding: 4px 0; }
      .hint { color: #e6a23c; margin-top: 12px; }
    }

    .msg {
      display: flex;
      margin-bottom: 16px;
      gap: 10px;

      &.user {
        flex-direction: row-reverse;
        .bubble {
          background: #409eff;
          color: #fff;
        }
      }

      &.assistant .bubble {
        background: #f4f4f5;
      }

      .avatar {
        width: 36px;
        height: 36px;
        border-radius: 50%;
        background: #dcdfe6;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 600;
        flex-shrink: 0;
      }

      .bubble {
        max-width: 78%;
        padding: 10px 14px;
        border-radius: 8px;
        font-size: 14px;
        line-height: 1.6;
        word-break: break-word;

        .card-area { margin-top: 10px; }

        .card {
          border: 1px solid #e4e7ed;
          border-radius: 6px;
          padding: 10px;
          background: #fff;
          color: #303133;

          .card-title {
            font-weight: 600;
            margin-bottom: 8px;
          }
          .kv {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 6px 16px;
            font-size: 13px;
            span { color: #909399; margin-right: 6px; }
          }
          .actions {
            margin-top: 10px;
            text-align: right;
          }
          .hint { color: #e6a23c; font-size: 12px; margin-top: 6px; }
          .voucher-no {
            font-family: monospace;
            font-size: 18px;
            font-weight: bold;
            color: #67c23a;
            text-align: center;
            padding: 8px;
            background: #f0f9eb;
            border-radius: 4px;
            margin-bottom: 8px;
          }
        }

        .citations {
          margin-top: 8px;
          border-top: 1px dashed #dcdfe6;
          padding-top: 6px;
        }
      }
    }
  }

  .chat-input {
    margin-top: 12px;
    display: flex;
    background: #fff;
    padding: 10px;
    border-radius: 8px;
    box-shadow: 0 1px 4px rgba(0,0,0,0.06);
    flex-shrink: 0;
  }
}
</style>