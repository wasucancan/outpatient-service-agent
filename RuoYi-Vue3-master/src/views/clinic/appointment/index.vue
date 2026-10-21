<template>
  <div class="app-container">
    <el-form :model="queryParams" ref="queryRef" :inline="true" v-show="showSearch">
      <el-form-item label="预约单号" prop="appointmentNo">
        <el-input v-model="queryParams.appointmentNo" placeholder="单号" clearable style="width:200px" @keyup.enter="handleQuery"/>
      </el-form-item>
      <el-form-item label="患者ID" prop="patientId">
        <el-input v-model="queryParams.patientId" placeholder="患者" clearable style="width:100px"/>
      </el-form-item>
      <el-form-item label="医生ID" prop="doctorId">
        <el-input v-model="queryParams.doctorId" placeholder="医生" clearable style="width:100px"/>
      </el-form-item>
      <el-form-item label="就诊日期" prop="visitDate">
        <el-date-picker v-model="queryParams.visitDate" type="date" value-format="YYYY-MM-DD" style="width:160px"/>
      </el-form-item>
      <el-form-item label="状态" prop="status">
        <el-select v-model="queryParams.status" placeholder="全部" clearable style="width:120px">
          <el-option label="已预约" value="BOOKED"/>
          <el-option label="已完成" value="COMPLETED"/>
          <el-option label="已取消" value="CANCELLED"/>
          <el-option label="爽约" value="NO_SHOW"/>
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="Search" @click="handleQuery">搜索</el-button>
        <el-button icon="Refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5">
        <el-button type="danger" plain icon="Delete" :disabled="multiple" @click="handleDelete" v-hasPermi="['clinic:appointment:remove']">删除</el-button>
      </el-col>
      <right-toolbar v-model:showSearch="showSearch" @queryTable="getList"/>
    </el-row>

    <el-table v-loading="loading" :data="apptList" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="55" align="center"/>
      <el-table-column label="预约单号" prop="appointmentNo" width="200"/>
      <el-table-column label="患者" prop="patientId" width="80"/>
      <el-table-column label="科室" prop="departmentId" width="80"/>
      <el-table-column label="医生" prop="doctorId" width="80"/>
      <el-table-column label="就诊日期" prop="visitDate" width="120"/>
      <el-table-column label="时段" prop="period" width="70">
        <template #default="scope">{{ scope.row.period==='AM'?'上午':'下午' }}</template>
      </el-table-column>
      <el-table-column label="状态" prop="status" width="100">
        <template #default="scope">
          <el-tag v-if="scope.row.status==='BOOKED'" type="success">已预约</el-tag>
          <el-tag v-else-if="scope.row.status==='COMPLETED'" type="info">已完成</el-tag>
          <el-tag v-else-if="scope.row.status==='CANCELLED'" type="danger">已取消</el-tag>
          <el-tag v-else type="warning">爽约</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="来源" prop="source" width="100"/>
      <el-table-column label="创建时间" prop="createTime" width="180"/>
      <el-table-column label="操作" align="center" width="150">
        <template #default="scope">
          <el-button v-if="scope.row.status==='BOOKED'" link type="danger" icon="Close" @click="handleCancel(scope.row)" v-hasPermi="['clinic:appointment:cancel']">取消</el-button>
          <el-button link type="danger" icon="Delete" @click="handleDelete(scope.row)" v-hasPermi="['clinic:appointment:remove']">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total>0" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList"/>
  </div>
</template>

<script setup name="ClinicAppointment">
import { listAppointment, cancelAppointment, delAppointment } from "@/api/clinic/appointment"
const { proxy } = getCurrentInstance()
const apptList = ref([])
const loading = ref(true)
const showSearch = ref(true)
const ids = ref([])
const multiple = ref(true)
const total = ref(0)

const data = reactive({
  queryParams: { pageNum:1, pageSize:10, appointmentNo:null, patientId:null, doctorId:null, visitDate:null, status:null }
})
const { queryParams } = toRefs(data)

function getList() {
  loading.value = true
  listAppointment(queryParams.value).then(r => {
    apptList.value = r.rows; total.value = r.total; loading.value = false
  })
}
function handleQuery() { queryParams.value.pageNum = 1; getList() }
function resetQuery() { proxy.resetForm("queryRef"); handleQuery() }
function handleSelectionChange(s) { ids.value = s.map(i => i.appointmentId); multiple.value = !s.length }

function handleCancel(row) {
  proxy.$prompt('请输入取消原因', '取消预约', { inputValue: '后台人工取消' }).then(({ value }) => {
    return cancelAppointment(row.appointmentId, value)
  }).then(() => {
    proxy.$modal.msgSuccess("取消成功，号源已返还"); getList()
  }).catch(() => {})
}
function handleDelete(row) {
  const aids = row.appointmentId || ids.value
  proxy.$modal.confirm('是否确认删除预约ID为"' + aids + '"的数据项？').then(() => delAppointment(aids)).then(() => {
    getList(); proxy.$modal.msgSuccess("删除成功")
  }).catch(() => {})
}
getList()
</script>