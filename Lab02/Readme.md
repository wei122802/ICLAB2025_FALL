# Lab02 SUDOKU
## 題目說明

### **▲  Inputs**
- clk
- rst_n
- in_valid
- in (4 bits)：1~9，0則是空位(使用raster scan oder，81cycle結束)

### **▲ Output**
- out_valid 
- out(4 bits)：1~9，一個(使用raster scan oder，81cycle結束)
  
### **▲ 主要流程**
- 封包解密：
    1. 解碼每個封包的內部資訊，包含 req_valid、QoS、mode等等...
    2. 使用類似於簡單版的SPECK32/64密碼解密輸入的封包
- 優先度計算與排序：依據封包解密結果計算優先分數，並依規則排序封包順序

- 通道分配：若通道未滿，則直接分配；若滿則依0 > 1 > 2 的順序找替代通道

- Mask檢查：檢查封包是否符合門檻條件，若失敗仍占用資源

- Re-balance：檢查三通道負載，若其中一通道過載，照0 > 1 >2的順序移動至其他通道

---
## 注意事項
- 儘量優先縮短 **critical path**  ，因為這次SPEC規定cycle time要在36.5ns以內，我身邊蠻多人都這邊卡關的
- 第一個Lab就有隱藏測資，且隱藏測資蠻好通過的，所以建議自己寫個python生隱藏測資

---
## $Performance$ = $Cycle time$ * $Latency^{1.5}$ * $Area^{1.5}$
| **Rank** | demo         | Cycle time | Area     | Latency | 1st_demo Rate |
| -------- | ------------ | ---------- | -------- | ------- | ------------- |
| **26**   | **1st_demo** | 5.7        | 207514.1 | 92773   | 83.67%        |

---
## Tips
- 計算優先度的部分可以用LUT去實現，可避免使用乘法器以及減法器
- 使用 **merge sort**，可以參考[別人統計的排序網路](https://zhuanlan.zhihu.com/p/410412547)
- Mask計算方式用到 *score and 0x6* 或者 *src_hint xor 0x3* 這種邏輯
  - 把 *score and 0x6*　看成 score[2:1]
  - 把 *src_hint xor 0x3* 看成 src_hint[1:0]要做反向
  - 因Threshold使用到除法跟加法，一樣可以用LUT去做處理
- 可以使用case(1)的方式去替代多層的if elseif else這種電路 [case(1)的用法](https://zhuanlan.zhihu.com/p/410412547)
---