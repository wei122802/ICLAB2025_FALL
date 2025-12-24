# Lab01 Multi-Packet Channel Arbiter
## 題目說明

### **▲  Inputs**
| 名稱             | 位元數   | 說明                                  |
| ---------------- | -------- | ------------------------------------- |
| packets          | 128 bits | 8 個 packet的資訊，每個資訊佔 16 bits |
| channel_load     | 12 bits  | 3個通道的使用量                       |
| channel_capacity | 9 bits   | 3個通道的容量                         |
| KEY              | 64 bits  | 解密用之金鑰                          |

### **▲ Output**
- grant_channel (16 bits)：8個封包的channel位置
  
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
## $Performance$ =  $Cycle time^{2}$ * $Area$

| **Rank** | demo         | 1st_demo Rate | Cycle time | Area   |
| -------- | ------------ | ------------- | ---------- | ------ |
| **10**   | **1st_demo** | **72.72%**    | 30.7       | 200083 |

---
## Tips
- 計算優先度的部分可以用LUT去實現，可避免使用乘法器以及減法器
- 使用 **merge sort**，可以參考[別人統計的排序網路](https://zhuanlan.zhihu.com/p/410412547)
- Sorting時，我為了保留原始封包的prefer_channel、req_valid以及原本位置，所以我先包裝起來再丟進Sorting，而排序判斷時不需要考慮priority_score以外的資訊，只有在交換時整包一起交換，這樣可以減少後面的判斷面積。
- Mask計算方式用到 *score and 0x6* 或者 *src_hint xor 0x3* 這種邏輯
  - 把 *score and 0x6*　看成 score[2:1]
  - 把 *src_hint xor 0x3* 看成 src_hint[1:0]要做反向
  - 因Threshold使用到除法跟加法，一樣可以用LUT去做處理
- 可以使用case(1)的方式去替代多層的if elseif else這種電路 [case(1)的用法](https://zhuanlan.zhihu.com/p/410412547)
  ```verilog
    case (1)
        ((allo[15:14] == largest_load_ch)&& mask[7]) :  re_ch_pos = 4'b0000; 
        ((allo[13:12] == largest_load_ch)&& mask[6]) :  re_ch_pos = 4'b0001; 
        ((allo[11:10] == largest_load_ch)&& mask[5]) :  re_ch_pos = 4'b0010;  
        ((allo[9:8]   == largest_load_ch)&& mask[4]) :  re_ch_pos = 4'b0011; 
        ((allo[7:6]   == largest_load_ch)&& mask[3]) :  re_ch_pos = 4'b0100; 
        ((allo[5:4]   == largest_load_ch)&& mask[2]) :  re_ch_pos = 4'b0101; 
        ((allo[3:2]   == largest_load_ch)&& mask[1]) :  re_ch_pos = 4'b0110; 
        ((allo[1:0]   == largest_load_ch)&& mask[0]) :  re_ch_pos = 4'b0111;    
        default: re_ch_pos = 4'b1000;
    endcase
    ```
---