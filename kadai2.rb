#!/usr/bin/env ruby
# coding: utf-8
#
# 表題: データ解析スクリプト. 10 分平均から 1 日平均を作る.
#

require 'csv'
require 'narray'
require 'date'
require 'fileutils'

###
### デバイス毎の設定
###

# デバイス名
myid = ARGV[0] 

# 公開ディレクトリ
pubdir = "/iotex/graph_1week/#{myid}"


###
### 初期化
###

# データ置き場
srcdir = "/iotex/data_csv_10min/#{myid}/"

# 公開ディレクトリの作成
FileUtils.rm_rf(   pubdir ) if    FileTest.exists?( pubdir )
FileUtils.mkdir_p( pubdir ) until FileTest.exists?( pubdir )

# 欠損値
miss = 999.9

# csv ファイルに含まれる変数の一覧
vars = [
  "time","temp","temp2","temp3","humi","humi2","humi3",
  "dp","dp2","dp3","pres","bmptemp","dietemp","objtemp","lux",
  "didx","didx2","didx3"
]


###
### データの取得とグラフの作成
### 
  
# 配列の初期化
time_list = Array.new
vars_list = Array.new
num = vars.size - 1 # 時刻分を除く
num.times do |i|
  vars_list[i] = Array.new
end

(DateTime.parse('#{ARGV[2]')..DateTime.now).each do |time_from|
 # csv ファイルの読み込み. 配列化
 Dir.glob("#{srcdir}/*csv").sort.each do |csvfile|
   CSV.foreach( csvfile ) do |item|
 #    p item
    
    # 時刻. DateTime オブジェクト化.
    time = DateTime.parse( "#{item[0]} JST" )
    
     # 7日分の毎正時のデータを取得.
     if time >= time_from && time <= time_from + 1 && time.min == 0
       time_list.push( time )  # 時刻
       num.times do |i|
         vars_list[i].push( item[i+1].to_f ) #各データ
       end
     end
   end
 end

 next if temp_list.min == temp_list.max

 # NArray オブジェクトへ変換. 解析が容易になる. 
 Numo.gnuplot do
   set title:    "#{ARCV[1]}(温度)
   set ylabel:   " (C)"
   set xlabel:   "time"
   set xdata:    "time"
   set timefmt_x:"%Y-%m-%dT%H:%M:%S+09:00"
   set format_x: "%Y/%m/%d"
   set xtics:    "rotate by -60"
   set terminal: "png"
   set output:   "#{pubdir}/temp/#{myid}_temp_#{time_from.strftime("%Y%m%d")}.png"
   set key: "box"
   set :datafile, :missing, "999.9"

   plot [time_list, temp_list["mean"], using:'1:($2)', with:"linespoints", lc_rgb:"green", lw:3, title:"mean"]
 end
end

###
### 統計処理
###

# 初期化
count = 24 # 24 時間

# 平均を取る開始時刻の添字. 時刻が 00:00:00 となるよう調整. 
time0= DateTime.new(
  time_list[0].year, time_list[0].month, time_list[0].day + 1,
  0, 0, 0, "JST"
)
idx0 = time_list.index( time0 )

# 平均を取る終了時刻の添字
idx1 = idx0 + count

# 時刻をずらしながら 1 日の統計量を作成する. 
while (time_list[idx0] + 1 < time_list[-1]) do 

  # 配列初期化
  time0  = time_list[idx0]
  mean   = Array.new( num, miss )  # 欠損値
  min    = Array.new( num, miss )  # 欠損値
  max    = Array.new( num, miss )  # 欠損値
  stddev = Array.new( num, miss )  # 欠損値
  median = Array.new( num, miss )  # 欠損値
  
  puts "#{time0} : #{time_list[idx0+1]}..#{time_list[idx1]}"
  
  # 1 つでも欠損値が含まれていたら日平均は欠損値扱いに.
  # 欠損値が含まれていない場合は idx2 は nil になる. 
  idx2 = ( vars_list_narray[0][idx0+1..idx1] ).to_a.index( miss )    
  unless ( idx2 )
    num.times do |i|
      mean[i]  = vars_list_narray[i][idx0+1..idx1].mean(0)
      min[i]   = # ... 自分で書く ...
      max[i]   = # ... 自分で書く ...
      stddev[i]= # ... 自分で書く ...
      median[i]= # ... 自分で書く ...
    end
  end      

  # ファイルの書き出し (平均値)
  csv = open("#{pubdir}/#{myid}_mean.csv", "a")
  csv.puts "#{time0.strftime("%Y/%m/%d")},#{mean.join(',')},\n"
  csv.close
  # 最小・最大・標準偏差・中央値のファイル出力
  # ... 自分で書く ...

  # 添字の更新
  idx0 = idx1 
  idx1 = idx0 + count  # 24時間分進める
end

