<template>
  <div class="app-container">
    <el-form :model="queryParams" ref="queryRef" :inline="true" v-show="showSearch">
      <el-form-item label="药品ID" prop="drugId">
        <el-input v-model="queryParams.drugId" placeholder="药品" clearable style="width:120px" @keyup.enter="handleQuery"/>
      </el-form-item>
      <el-form-item label="批次号" prop="batchNo">
        <el-input v-model="queryParams.batchNo" placeholder="批次号" clearable style="width:180px" @keyup.enter="handleQuery"/>
      </el-form-item>
      <el-form-item label="状态" prop="batchStatus">
        <el-select v-model="queryParams.batchStatus" placeholder="全部" clearable style="width:140px">
          <el-option label="正常" value="NORMAL"/>
          <el-option label="临期" value="NEAR_EXPIRY"/>
          <el-option label="过期" value="EXPIRED"/>
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="Search" @click="handleQuery">搜索</el-button>
        <el-button icon="Refresh" @click="resetQuery">重置</el-button>
        <el-button type="warning" icon="Warning" @click="handleExpiring">临期预警</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5">
        <el-button type="primary" plain icon="Plus" @click="handleAdd" v-hasPermi="['clinic:drugbatch:add']">新增</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button type="danger" plain icon="Delete" :disabled="multiple" @click="handleDelete" v-hasPermi="['clinic:drugbatch:remove']">删除</el-button>
      </el-col>
      <right-toolbar v-model:showSearch="showSearch" @queryTable="getList"/>
    </el-row>

    <el-table v-loading="loading" :data="batchList" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="55" align="center"/>
      <el-table-column label="批次ID" prop="batchId" width="90"/>
      <el-table-column label="药品ID" prop="drugId" width="90"/>
      <el-table-column label="批次号" prop="batchNo" width="150"/>
      <el-table-column label="供应商" prop="supplierName" width="180" show-overflow-tooltip/>
      <el-table-column label="生产日期" prop="productionDate" width="120"/>
      <el-table-column label="有效期" prop="expiryDate" width="120"/>
      <el-table-column label="入库" prop="inboundQty" width="80"/>
      <el-table-column label="可用库存" prop="availableQty" width="100">
        <template #default="scope">
          <el-tag :type="scope.row.availableQty>0?'success':'info'">{{ scope.row.availableQty }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="状态" prop="batchStatus" width="110">
        <template #default="scope">
          <el-tag v-if="scope.row.batchStatus==='NORMAL'" type="success">正常</el-tag>
          <el-tag v-else-if="scope.row.batchStatus==='NEAR_EXPIRY'" type="warning">临期</el-tag>
          <el-tag v-else type="danger">过期</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" align="center" width="150">
        <template #default="scope">
          <el-button link type="primary" icon="Edit" @click="handleUpdate(scope.row)" v-hasPermi="['clinic:drugbatch:edit']">修改</el-button>
          <el-button link type="danger" icon="Delete" @click="handleDelete(scope.row)" v-hasPermi="['clinic:drugbatch:remove']">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total>0" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList"/>

    <el-dialog :title="title" v-model="open" width="700px" append-to-body>
      <el-form ref="batchRef" :model="form" :rules="rules" label-width="110px">
        <el-row>
          <el-col :span="12"><el-form-item label="药品ID" prop="drugId"><el-input v-model="form.drugId"/></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="批次号" prop="batchNo"><el-input v-model="form.batchNo"/></el-form-item></el-col>
        </el-row>
        <el-row>
          <el-col :span="12"><el-form-item label="供应商" prop="supplierName"><el-input v-model="form.supplierName"/></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="仓库位置" prop="warehouseLocation"><el-input v-model="form.warehouseLocation"/></el-form-item></el-col>
        </el-row>
        <el-row>
          <el-col :span="12"><el-form-item label="生产日期" prop="productionDate"><el-date-picker v-model="form.productionDate" type="date" value-format="YYYY-MM-DD" style="width:100%"/></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="有效期" prop="expiryDate"><el-date-picker v-model="form.expiryDate" type="date" value-format="YYYY-MM-DD" style="width:100%"/></el-form-item></el-col>
        </el-row>
        <el-row>
          <el-col :span="12"><el-form-item label="入库数量" prop="inboundQty"><el-input-number v-model="form.inboundQty" :min="0"/></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="可用库存" prop="availableQty"><el-input-number v-model="form.availableQty" :min="0"/></el-form-item></el-col>
        </el-row>
        <el-row>
          <el-col :span="12"><el-form-item label="采购价" prop="purchasePrice"><el-input-number v-model="form.purchasePrice" :precision="2" :min="0"/></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="状态" prop="batchStatus">
            <el-select v-model="form.batchStatus" style="width:100%">
              <el-option label="正常" value="NORMAL"/>
              <el-option label="临期" value="NEAR_EXPIRY"/>
              <el-option label="过期" value="EXPIRED"/>
            </el-select>
          </el-form-item></el-col>
        </el-row>
      </el-form>
      <template #footer>
        <el-button type="primary" @click="submitForm">确 定</el-button>
        <el-button @click="cancel">取 消</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup name="ClinicDrugBatch">
import { listDrugBatch, getDrugBatch, addDrugBatch, updateDrugBatch, delDrugBatch, listExpiring } from "@/api/clinic/drugbatch"
const { proxy } = getCurrentInstance()
const batchList = ref([])
const loading = ref(true)
const showSearch = ref(true)
const ids = ref([])
const multiple = ref(true)
const total = ref(0)
const title = ref("")
const open = ref(false)

const data = reactive({
  form: {},
  queryParams: { pageNum:1, pageSize:10, drugId:null, batchNo:null, batchStatus:null },
  rules: {
    drugId: [{ required:true, message:"药品ID不能为空", trigger:"blur" }],
    batchNo: [{ required:true, message:"批次号不能为空", trigger:"blur" }],
    expiryDate: [{ required:true, message:"有效期不能为空", trigger:"change" }],
    inboundQty: [{ required:true, message:"入库数量不能为空", trigger:"blur" }],
    availableQty: [{ required:true, message:"可用库存不能为空", trigger:"blur" }]
  }
})
const { queryParams, form, rules } = toRefs(data)

function getList() {
  loading.value = true
  listDrugBatch(queryParams.value).then(r => {
    batchList.value = r.rows; total.value = r.total; loading.value = false
  })
}
function cancel() { open.value = false; reset() }
function reset() {
  form.value = {
    batchId:null, drugId:null, batchNo:null, supplierName:null,
    productionDate:null, expiryDate:null, inboundQty:0, availableQty:0,
    purchasePrice:0, warehouseLocation:null, batchStatus:"NORMAL"
  }
}
function handleQuery() { queryParams.value.pageNum = 1; getList() }
function resetQuery() { proxy.resetForm("queryRef"); handleQuery() }
function handleSelectionChange(s) { ids.value = s.map(i=>i.batchId); multiple.value = !s.length }

function handleExpiring() {
  loading.value = true
  listExpiring().then(r => {
    batchList.value = r.rows
    total.value = r.total
    loading.value = false
    proxy.$modal.msgSuccess(`临期/过期批次 ${r.total} 条`)
  })
}

function handleAdd() { reset(); open.value = true; title.value = "新增药品批次" }
function handleUpdate(row) {
  reset()
  getDrugBatch(row.batchId).then(r => {
    form.value = r.data; open.value = true; title.value = "修改药品批次"
  })
}
function submitForm() {
  proxy.$refs["batchRef"].validate(valid => {
    if (!valid) return
    if (form.value.batchId != null) {
      updateDrugBatch(form.value).then(() => { proxy.$modal.msgSuccess("修改成功"); open.value=false; getList() })
    } else {
      addDrugBatch(form.value).then(() => { proxy.$modal.msgSuccess("新增成功"); open.value=false; getList() })
    }
  })
}
function handleDelete(row) {
  const bids = row.batchId || ids.value
  proxy.$modal.confirm('是否确认删除批次ID为"' + bids + '"的数据项？').then(() => delDrugBatch(bids)).then(() => {
    getList(); proxy.$modal.msgSuccess("删除成功")
  }).catch(() => {})
}
getList()
</script>