import random

SEED = "WEI ICLAB"
random.seed(SEED)

datfile = open('dram.dat', 'w')
debugfile = open('debug.txt', 'w')

# 總共有 256 位玩家
for i in range(256):
    
    # 每個玩家有 3 個 4-byte (32-bit) entries，所以 base address 每次 +12
    # Player 0 從 0x10000 開始 [cite: 327]
    # Player 255 從 0x10000 + 255*12 = 0x10BFC 開始 [cite: 333]
    base = i*12 + 0x10000

    # 1. 根據 Table 1 產生隨機的玩家屬性 
    Exp = random.randint(0, 0xffff)     # 16 bits
    MP = random.randint(0, 0xffff)      # 16 bits
    HP = random.randint(0, 0xffff)      # 16 bits
    Attack = random.randint(0, 0xffff)  # 16 bits
    Defense = random.randint(0, 0xffff) # 16 bits

    # 產生合法的日期 (Month & Day)
    Month = random.randint(1, 12)
    Day = 0
    if(Month == 2):
      # 規格說明 2 月只有 28 天 
      Day = random.randint(1, 28)
    elif Month in [4, 6, 9, 11]:
      Day = random.randint(1, 30)
    else:
      Day = random.randint(1, 31)

    # 2. 根據 Figure 2 的範例  進行資料封裝 (Packing)

    # Entry 1 (Address: base): {MP, Exp}
    # 封裝格式: { MP[7:0], MP[15:8], Exp[7:0], Exp[15:8] } [cite: 177]
    MP_lower_8 = MP & 0xFF
    MP_upper_8 = (MP >> 8) & 0xFF
    Exp_lower_8 = Exp & 0xFF
    Exp_upper_8 = (Exp >> 8) & 0xFF
    # 格式: 0A E1 60 22
    line1 = f"{MP_lower_8:02X} {MP_upper_8:02X} {Exp_lower_8:02X} {Exp_upper_8:02X}"

    # Entry 2 (Address: base + 4): {Attack, Defense}
    # 封裝格式: { Defense[7:0], Defense[15:8], Attack[7:0], Attack[15:8] } [cite: 179]
    Def_lower_8 = Defense & 0xFF
    Def_upper_8 = (Defense >> 8) & 0xFF
    Atk_lower_8 = Attack & 0xFF
    Atk_upper_8 = (Attack >> 8) & 0xFF
    # 格式: 05 B4 93 D5
    line2 = f"{Def_lower_8:02X} {Def_upper_8:02X} {Atk_lower_8:02X} {Atk_upper_8:02X}"

    # Entry 3 (Address: base + 8): {HP, Date(M), Date(D)}
    # 封裝格式: { Date(D), Date(M), HP[7:0], HP[15:8] } [cite: 182, 183, 184]
    HP_lower_8 = HP & 0xFF
    HP_upper_8 = (HP >> 8) & 0xFF
    # 格式: 1D 0B 4F 36
    line3 = f"{Day:02X} {Month:02X} {HP_lower_8:02X} {HP_upper_8:02X}"

    # 3. 將資料寫入 dram.dat
    print(f"@{base:05X}", file=datfile)
    print(line1, file=datfile)
    
    print(f"@{base+4:05X}", file=datfile)
    print(line2, file=datfile)
    
    print(f"@{base+8:05X}", file=datfile)
    print(line3, file=datfile)

    # 4. 將可讀的資料寫入 debug.txt
    print(f"@player_no = {i}", file=debugfile)
    print(f"Day: {Month:02d}/{Day:02d}", file=debugfile)
    print(f"Exp: 0x{Exp:04X} ({Exp:04d}) \nMP: 0x{MP:04X} ({MP:04d})", file=debugfile)
    print(f"Attack: 0x{Attack:04X} ({Attack:04d})\nDefense: 0x{Defense:04X} ({Defense:04d})", file=debugfile)
    print(f"HP: 0x{HP:04X} ({HP:04d})", file=debugfile)
    print("-" * 20, file=debugfile)

datfile.close()
debugfile.close()

print("dram.dat and debug.txt generated successfully based on Lab09_Exercise.pdf.")