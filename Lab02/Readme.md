# Lab02 SUDOKU
## 題目說明

### **▲ Inputs**
| Signal   | Bits | Description                                                     |
| -------- | ---- | --------------------------------------------------------------- |
| clk      | 1    | 時鐘信號                                                        |
| rst_n    | 1    | 重置信號                                                        |
| in_valid | 1    | 輸入有效信號                                                    |
| in       | 4    | 輸入數字（1~9，0表示空位，使用raster scan order，81 cycle結束） |

### **▲ Output**
| Signal    | Bits | Description                                          |
| --------- | ---- | ---------------------------------------------------- |
| out_valid | 1    | 輸出有效信號                                         |
| out       | 4    | 輸出數字（1~9，使用raster scan order，81 cycle結束） |
  
### **▲ 主要流程**
| State        | Description                             |
| ------------ | --------------------------------------- |
| INPUT        | 接收 81 筆數獨輸入資料                  |
| SOLVE_UPDATE | 反覆執行 Naked / Hidden Single 更新棋盤 |
| OUTPUT       | 依序輸出完成後的棋盤                    |

- Possible Value 計算 : 對每個空格 (row, col)，計算 1~9 是否可填同時檢查Row 、Column、3X3是否已有該數字
- Naked Single : 若某一格board[row][col] == 0，且possible_values 只剩一個bit為 1
- Hidden Single :
  - Row Hidden Single : 同一個Row中某數字只出現在唯一一個 possible cell
  - Column Hidden Single: 同一個Column中某數字只出現在唯一一個 possible cell
  - Box Hidden Single: 同一個Box中某數字只出現在唯一一個 possible cell


---
## 注意事項
- 因題目尚未提及是否需要做backtracking
- 一樣有隱藏測資，所以建議自己寫個python生隱藏測資

---
## $Performance$ = $Cycle time$ * $Latency^{1.5}$ * $Area^{1.5}$
| **Rank** | demo         | Cycle time | Area     | Latency | 1st_demo Rate |
| -------- | ------------ | ---------- | -------- | ------- | ------------- |
| **26**   | **1st_demo** | 5.7        | 207514.1 | 92773   | 83.67%        |

---
## Tips
- 演算法是決定Performance的關鍵，使用one-hot encoding來表示possible value
---