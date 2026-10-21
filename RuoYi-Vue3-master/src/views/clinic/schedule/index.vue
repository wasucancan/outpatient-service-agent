<template>
  <div class="app-container">
    <el-form :model="queryParams" ref="queryRef" :inline="true" v-show="showSearch">
      <el-form-item label="科室ID" prop="departmentId">
        <el-input v-model="queryParams.departmentId" placeholder="科室" clearable style="width:100px" @keyup.enter="handleQuery"/>
      </el-form-item>
      <el-form-item label="医生ID" prop="doctorId">
        <el-input v-model="queryParams.doctorId" placeholder="医生" clearable style="width:100px" @keyup.enter="handleQuery"/>
      </el-form-item>
      <el-form-item label="就诊日期" prop="visitDate">
        <el-date-picker v-model="queryParams.visitDate" type="date" value-format="YYYY-MM-DD" style="width:160px" placeholder="选择日期"/>
      </el-form-item>
      <el-form-item label="时段" prop="period">
        <el-select v-model="queryParams.period" placeholder="全部" clearable style="width:100px">
          <el-option label="上午" value="AM"/><el-option label="下午" value="PM"/>
        </el-select>
      </el-form-item>
      <el-form-item label="状态" prop="status">
        <el-select v-model="queryParams.status" placeholder="全部" clearable style="width:120px">
          <el-option label="开放" value="OPEN"/><el-option label="关闭" value="CLOSED"/><el-option label="暂停" value="SUSPENDED"/>
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="Search" @click="handleQuery">搜索</el-button>
        <el-button icon="Refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5">
        <el-button type="primary" plain icon="Plus" @click="handleAdd" v-hasPermi="['clinic:schedule:add']">新增</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button type="danger" plain icon="Delete" :disabled="multiple" @click="handleDelete" v-hasPermi="['clinic:schedule:remove']">删除</el-button>
      </el-col>
      <right-toolbar v-model:showSearch="showSearch" @queryTable="getList"/>
    </el-row>

    <el-table v-loading="loading" :data="scheduleList" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="55" align="center"/>
      <el-table-column label="排班ID" prop="scheduleId" width="90"/>
      <el-table-column label="科室" prop="departmentId" width="80"/>
      <el-table-column label="医生" prop="doctorId" width="80"/>
      <el-table-column label="就诊日期" prop="visitDate" width="120"/>
      <el-table-column label="时段" prop="period" width="70">
        <template #default="scope">
          <el-tag :type="scope.row.period==='AM'?'success':'warning'">{{ scope.row.period==='AM'?'上午':'下午' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="开始" prop="startTime" width="100"/>
      <el-table-column label="结束" prop="endTime" width="100"/>
      <el-table-column label="总号源" prop="totalQuota" width="80"/>
      <el-table-column label="剩余" prop="remainingQuota" width="80">
        <template #default="scope">
          <el-tag :type="scope.row.remainingQuota>0?'success':'danger'">{{ scope.row.remainingQuota }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="状态" prop="status" width="100">
        <template #default="scope">
          <el-tag v-if="scope.row.status==='OPEN'">开放</el-tag>
          <el-tag v-else-if="scope.row.status==='CLOSED'" type="info">关闭</el-tag>
          <el-tag v-else type="danger">暂停</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" align="center" width="180" class-name="small-padding fixed-width">
        <template #default="scope">
          <el-button link type="primary" icon="Edit" @click="handleUpdate(scope.row)" v-hasPermi="['clinic:schedule:edit']">修改</el-button>
          <el-button link type="danger" icon="Delete" @click="handleDelete(scope.row)" v-hasPermi="['clinic:schedule:remove']">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total>0" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList"/>

    <el-dialog :title="title" v-model="open" width="600px" append-to-body>
      <el-form ref="scheduleRef" :model="form" :rules="rules" label-width="100px">
        <el-row>
          <el-col :span="12"><el-form-item label="科室ID" prop="departmentId"><el-input v-model="form.departmentId"/></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="医生ID" prop="doctorId"><el-input v-model="form.doctorId"/></el-form-item></el-col>
        </el-row>
        <el-row>
          <el-col :span="12"><el-form-item label="就诊日期" prop="visitDate"><el-date-picker v-model="form.visitDate" type="date" value-format="YYYY-MM-DD" style="width:100%"/></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="时段" prop="period"><el-select v-model="form.period" style="width:100%"><el-option label="上午" value="AM"/><el-option label="下午" value="PM"/></el-select></el-form-item></el-col>
        </el-row>
        <el-row>
          <el-col :span="12"><el-form-item label="开始时间" prop="startTime"><el-input v-model="form.startTime" placeholder="08:00:00"/></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="结束时间" prop="endTime"><el-input v-model="form.endTime" placeholder="12:00:00"/></el-form-item></el-col>
        </el-row>
        <el-row>
          <el-col :span="12"><el-form-item label="总号源" prop="totalQuota"><el-input-number v-model="form.totalQuota" :min="1"/></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="剩余号源" prop="remainingQuota"><el-input-number v-model="form.remainingQuota" :min="0"/></el-form-item></el-col>
        </el-row>
        <el-form-item label="状态" prop="status">
          <el-select v-model="form.status" style="width:100%">
            <el-option label="开放" value="OPEN"/><el-option label="关闭" value="CLOSED"/><el-option label="暂停" value="SUSPENDED"/>
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button type="primary" @click="submitForm">确 定</el-button>
          <el-button @click="cancel">取 消</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>
<script setup name="ClinicSchedule">
import { listSchedule, getSchedule, addSchedule, updateSchedule, delSchedule } from "@/api/clinic/schedule"

const { proxy } = getCurrentInstance()
const scheduleList = ref([])
const loading = ref(true)
const showSearch = ref(true)
const ids = ref([])
const multiple = ref(true)
const total = ref(0)
const title = ref("")
const open = ref(false)

const data = reactive({
  form: {},
  queryParams: {
    pageNum: 1, pageSize: 10,
    departmentId: null, doctorId: null,
    visitDate: null, period: null, status: null
  },
  rules: {
    departmentId: [{ required: true, message: "科室不能为空", trigger: "blur" }],
    doctorId: [{ required: true, message: "医生不能为空", trigger: "blur" }],
    visitDate: [{ required: true, message: "就诊日期不能为空", trigger: "change" }],
    period: [{ required: true, message: "时段不能为空", trigger: "change" }],
    startTime: [{ required: true, message: "开始时间不能为空", trigger: "blur" }],
    endTime: [{ required: true, message: "结束时间不能为空", trigger: "blur" }],
    totalQuota: [{ required: true, message: "总号源不能为空", trigger: "blur" }],
    remainingQuota: [{ required: true, message: "剩余号源不能为空", trigger: "blur" }]
  }
})
const { queryParams, form, rules } = toRefs(data)

function getList() {
  loading.value = true
  listSchedule(queryParams.value).then(response => {
    scheduleList.value = response.rows
    total.value = response.total
    loading.value = false
  })
}

function cancel() { open.value = false; reset() }
function reset() {
  form.value = {
    scheduleId: null, departmentId: null, doctorId: null,
    visitDate: null, period: "AM", startTime: "08:00:00", endTime: "12:00:00",
    totalQuota: 10, remainingQuota: 10, status: "OPEN"
  }
}
function handleQuery() { queryParams.value.pageNum = 1; getList() }
function resetQuery() { proxy.resetForm("queryRef"); handleQuery() }
function handleSelectionChange(selection) {
  ids.value = selection.map(item => item.scheduleId)
  multiple.value = !selection.length
}

function handleAdd() { reset(); open.value = true; title.value = "添加排班" }
function handleUpdate(row) {
  reset()
  getSchedule(row.scheduleId).then(response => {
    form.value = response.data
    open.value = true
    title.value = "修改排班"
  })
}

function submitForm() {
  proxy.$refs["scheduleRef"].validate(valid => {
    if (!valid) return
    if (form.value.scheduleId != null) {
      updateSchedule(form.value).then(() => {
        proxy.$modal.msgSuccess("修改成功")
        open.value = false
        getList()
      })
    } else {
      addSchedule(form.value).then(() => {
        proxy.$modal.msgSuccess("新增成功")
        open.value = false
        getList()
      })
    }
  })
}

function handleDelete(row) {
  const sids = row.scheduleId || ids.value
  proxy.$modal.confirm('是否确认删除排班ID为"' + sids + '"的数据项？').then(() => {
    return delSchedule(sids)
  }).then(() => {
    getList()
    proxy.$modal.msgSuccess("删除成功")
  }).catch(() => {})
}

getList()
</script>