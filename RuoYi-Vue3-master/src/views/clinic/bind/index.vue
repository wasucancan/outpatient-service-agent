<template>
  <div class="app-container">
    <el-form :model="queryParams" ref="queryRef" :inline="true" v-show="showSearch">
      <el-form-item label="用户ID" prop="userId">
        <el-input v-model="queryParams.userId" placeholder="用户ID" clearable style="width:120px" @keyup.enter="handleQuery"/>
      </el-form-item>
      <el-form-item label="患者ID" prop="patientId">
        <el-input v-model="queryParams.patientId" placeholder="患者ID" clearable style="width:120px" @keyup.enter="handleQuery"/>
      </el-form-item>
      <el-form-item label="绑定类型" prop="bindType">
        <el-select v-model="queryParams.bindType" placeholder="全部" clearable style="width:140px">
          <el-option label="本人" value="SELF"/>
          <el-option label="前台代办" value="FRONTDESK"/>
        </el-select>
      </el-form-item>
      <el-form-item label="状态" prop="status">
        <el-select v-model="queryParams.status" placeholder="全部" clearable style="width:120px">
          <el-option label="有效" value="0"/>
          <el-option label="失效" value="1"/>
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="Search" @click="handleQuery">搜索</el-button>
        <el-button icon="Refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5">
        <el-button type="primary" plain icon="Plus" @click="handleAdd" v-hasPermi="['clinic:bind:add']">新增</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button type="danger" plain icon="Delete" :disabled="multiple" @click="handleDelete" v-hasPermi="['clinic:bind:remove']">删除</el-button>
      </el-col>
      <right-toolbar v-model:showSearch="showSearch" @queryTable="getList"/>
    </el-row>

    <el-table v-loading="loading" :data="bindList" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="55" align="center"/>
      <el-table-column label="绑定ID" prop="bindId" width="100"/>
      <el-table-column label="用户ID" prop="userId" width="100"/>
      <el-table-column label="患者ID" prop="patientId" width="100"/>
      <el-table-column label="绑定类型" prop="bindType" width="120">
        <template #default="scope">
          <el-tag v-if="scope.row.bindType==='SELF'" type="success">本人</el-tag>
          <el-tag v-else type="warning">前台代办</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="核验人" prop="verifiedBy" width="100"/>
      <el-table-column label="核验时间" prop="verifyTime" width="180"/>
      <el-table-column label="状态" prop="status" width="100">
        <template #default="scope">
          <el-tag :type="scope.row.status==='0'?'success':'info'">{{ scope.row.status==='0'?'有效':'失效' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="创建时间" prop="createTime" width="180"/>
      <el-table-column label="操作" align="center" class-name="small-padding fixed-width">
        <template #default="scope">
          <el-button link type="primary" icon="Edit" @click="handleUpdate(scope.row)" v-hasPermi="['clinic:bind:edit']">修改</el-button>
          <el-button link type="danger" icon="Delete" @click="handleDelete(scope.row)" v-hasPermi="['clinic:bind:remove']">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total>0" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList"/>
  </div>
</template>
<script setup name="ClinicBind">
import { listBind, getBind, addBind, updateBind, delBind } from "@/api/clinic/bind"

const { proxy } = getCurrentInstance()
const bindList = ref([])
const loading = ref(true)
const showSearch = ref(true)
const ids = ref([])
const multiple = ref(true)
const total = ref(0)

const data = reactive({
  form: {},
  queryParams: {
    pageNum: 1,
    pageSize: 10,
    userId: null,
    patientId: null,
    bindType: null,
    status: null
  }
})
const { queryParams, form } = toRefs(data)

function getList() {
  loading.value = true
  listBind(queryParams.value).then(response => {
    bindList.value = response.rows
    total.value = response.total
    loading.value = false
  })
}

function handleQuery() {
  queryParams.value.pageNum = 1
  getList()
}

function resetQuery() {
  proxy.resetForm("queryRef")
  handleQuery()
}

function handleSelectionChange(selection) {
  ids.value = selection.map(item => item.bindId)
  multiple.value = !selection.length
}

function handleAdd() {
  proxy.$modal.msgWarning("绑定关系请通过后台数据管理，或使用 Swagger 调 /clinic/bind 接口")
}

function handleUpdate(row) {
  proxy.$modal.msgWarning("绑定关系修改请通过后台数据管理")
}

function handleDelete(row) {
  const bindIds = row.bindId || ids.value
  proxy.$modal.confirm('是否确认删除绑定ID为"' + bindIds + '"的数据项？').then(() => {
    return delBind(bindIds)
  }).then(() => {
    getList()
    proxy.$modal.msgSuccess("删除成功")
  }).catch(() => {})
}

getList()
</script>