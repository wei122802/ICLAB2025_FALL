MVDM_done.v
Area: 2347985.253265
Average Execution Latency: 152.115625 cycles
Performance :   837,981,281,931,585

MVDM_8X8done.v
Area: 2637366.732487    681,658,921,599,657
Average Execution Latency: 98.115625 cycles
Performance :   681,658,921,599,657

Startpoint: point_L_cnt_reg_0_
              (rising edge-triggered flip-flop clocked by clk)
Endpoint: bluex_reg_reg_1__11_
            (rising edge-triggered flip-flop clocked by clk)


Cycle: 7.00 but 02 slack negative
Area: 3619094.526048
Performance: 91684916319294.18425348812800

Cycle: 8.00
Area: 3161836.297243
Performance: 79977670164506.59719520839200

optimize 1 : only reduce Clip((Val+16)>>>5) 
Cycle: 8.00
Area: 3163295.577848
Performance: 80051511302661.69782648883200

optimize 2 : only reduce Clip((Val+512)>>>10)
Cycle: 8.00
Area: 3158430.265419
Performance: 79805453932117.87829796448800

optimize 3 : reduce Clip((Val+16)>>>5) and Clip((Val+512)>>>10) 
Cycle: 8.00
Area: 3158402.142064
Performance: 79804032727955.70910544076800

optimize 4 : interpolation blue module not good 
Cycle: 8.00
Area: 3170432.622323
Performance: 80413144101519.15486333063200

optimize 5 : early output 
Average Execution Latency: 69.379688 cycles
Cycle: 8.00
Area: 3158592.754574
Performance: 79813665513978.95198337180800

SPEC : 0~255 opt_v2
Cycle: 8.00
Area: 3537265.402451
Performance: 100097972219014.67997445920800

reduce bits
Cycle: 8.00
Area: 3376113.215533
Performance: 91185123552772.58329979271200

retime
Cycle: 8.00
Area: 3336878.221060
Performance: 89078050097476.40182018880000

reduce GetMV state

 Average Execution Latency: 66.243750 cycles
Cycle: 8.00
Area: 3420335.382329
Performance: 93589553020893.33284371392800

pipeline residual8X8 reg

Average Execution Latency: 68.010937 cycles 
Cycle: 8.00
Area: 2831373.068493
Performance: 64133387623899.73175432839200

Cycle: 6.00
Area: 3107761.626993
Performance: 57949093981261.07079733229400

SRAM early read
Average Execution Latency: 60.583594 cycles 
Cycle: 6.00
Area: 3113017.540421
Performance: 58145269241812.87421314344600

SRAM address early
Average Execution Latency:    57.084688 cycles
CT:6.0 have negative slack

Cycle: 6.20
Area: 3053308.860798
Performance: 57800708996450.99935542018480

Average Execution Latency:    44.587969 cycles
6.2 02 have problem
Cycle: 6.30
Area: 3114408.075529
Performance: 61107087263797.57102236799830


Average Execution Latency:    43.585781 cycles
Cycle: 6.30
Area: 3118376.570984
Performance: 61262916362310.15894158801280

reduce FSM state
Cycle: 6.30
Area: 3118551.559518
Performance: 61269792125044.54434727164120


reduce some logic
Cycle: 6.30
Area: 3116232.957707
Performance: 61178719434205.69867939644870

GreenL0 L1 remove rst_n
Cycle: 6.30
Area: 3091422.041360
Performance: 60208408498180.50616909248000

Green SATD remove rst_n

Cycle: 6.30
Area: 3080653.978504
Performance: 59789702292216.89927269150080


Y_pipe remove rst_n 
Cycle: 6.30
Area: 3075963.653431
Performance: 59607780102540.08599185209430

bluex_L0 remove rst_n 
Cycle: 6.30
Area: 3064142.535105
Performance: 59150507695270.08579137445750

bluex_reg remove rst_n XXXXXX
Cycle: 6.30
Area: 3067457.948271
Performance: 59278579065788.87734490347830

in_data_image remove rst_n 
Cycle: 6.30
Area: 3064851.865277
Performance: 59177896823379.00879720639270

y_calu optimize  X
Cycle: 6.30
Area: 3083219.446454
Performance: 59889325576450.29409099693080

Cycle: 6.30
Area: 3064142.535105
Performance: 59150507695270.08579137445750


register together
retiming
Cycle: 8.00
Area: 3123373.129231
Performance: 78043677635217.99221321088800

Cycle: 7.00
Area: 3225797.824308
Performance: 72840401223171.58504975204800

APR
====================
original 9.5 cycle time
Cycle: 9.50
Area: 2735566.701938
Performance: 71091589217143.49206308051800

compiler twice and add retime
Cycle: 9.50
Area: 2755649.788977
Performance: 72139254715145.35399171202550

retime
Cycle: 9.50
Area: 2729554.585857
Performance: 70779448253143.29845203226550

Total area of Chip: 5725640.232 um^2 
CT : 11.6

APR Version2

11.4
Cycle: 11.40
Area: 2699462.760932
Performance: 83072930853308.22451479831360

Cycle: 11.00 **********************
Area: 2705056.153346
Performance: 80490616720305.64093695287600

opt interpolation_blue formula
Cycle: 11.00
Area: 2721795.706958
Performance: 81489890574564.98910575140400


opt latency early start
Average Execution Latency:    42.585781 cycles
Cycle: 11.00
Area: 2721898.825487
Performance: 81496065378062.61088865885900

reduce blue pipeline reg
Average Execution Latency:    41.835625 cycles 
Cycle: 11.00
Area: 2712036.956549
Performance: 80906588990563.18765388341100

optimize satd_total logic
Cycle: 11.00
Area: 2707677.860699
Performance: 80646713370514.64573645461100

optimize: remove sram reg 
Average Execution Latency:    39.336719 cycles 
Cycle: 11.00
Area: 2695066.166502
Performance: 79897198060061.64585607604400

satd_cnt_pipe remove rst_n 
Cycle: 11.00
Area: 2693306.905427
Performance: 79792922955028.39434257561900

satd reduce 1cycle
Average Execution Latency:    38.871875 cycles
Cycle: 11.00
Area: 2702918.790203
Performance: 80363469850756.94041659329900

early one cycle output ****************
Average Execution Latency:    38.336719 cycles
Cycle: 11.00
Area: 2695266.155192
Performance: 79909056120558.12851412550400

reduce one bit in calu_cnt
Cycle: 11.00
Area: 2691003.927732
Performance: 79656523529759.56186530206400

remove retiming **********************
Cycle: 11.00
Area: 2687526.025491
Performance: 79450757514605.96299970189100

Cycle: 11.00
Area: 2700543.942315
Performance: 80222313428116.66252315147500



APR version2
Total area of Chip: 5375650.058 um^2
CTS : 11.5

APR version3 ut: 0.85 ratio:1.16
Total area of Chip: 5105029.706 um^2 
CTS : 11.5 maybe 11.4

================================================
APR version6
XX ut: 0.9 ratio:1.23 placement over 100% problem  
try 0.88 ratio:1.19 CTS have negative  0.87645 1.19590



Cycle: 11.00 // try 10.9~11.1 best is 11.0
Area: 2687526.025491
Performance: 79450757514605.96299970189100

try 0.87 ratio:1.184  version6  **********************
Total area of Chip: 5035183.705 um^2 
CTS : 11.4

===================================================
Cycle: 11.00
Area: 2685626.147171
Performance: 79338465826054.04726433565100

Cycle: 11.00
Area: 2685429.284663
Performance: 79326834872181.95075725925900

Cycle: 11.00
Area: 2674698.721538
Performance: 78694145760967.12831593988400

===============================================
version 7 CTS : 11.1 *************************
try 0.8725 ratio:1.199
Cycle: 11.10
Area: 2671661.415678
Performance: 79229299392250.58365661649240

Total area of Chip: 5001011.611 um^2