#!/usr/bin/env ruby
# coding: utf-8
#
# 表題: グラフ作成のためのスクリプト. CSV ファイル利用版.
#

require 'csv'
require 'date'
require 'fileutils'
require 'numo/gnuplot'

###
### デバイス毎の設定
###

# デバイス名
myid = ARGV[0]

# 公開ディレクトリ
pubdir = "/iotex/graph_1month/#{myid}" 

# データ置き場
srcdir = "/home/j1431/public_html/data_csv_1day"


###
### 初期化
###

# #公開ディレクトリの作成
(DateTime.parse("#{ARGV[2]}")..DateTime.now).each do |time_from|
pubdir_temp = "#{pubdir}/temp/#{time_from.strftime("%Y-%m")}"
FileUtils.mkdir_p( pubdir_temp ) until FileTest.exists?( pubdir_temp )
# 欠損値
miss = 999.9
##
## csv ファイルに含まれる変数の一覧
#vars = [
#  "dp","dp2","dp3","pres","bmptemp","dietemp","objtemp","lux",
#  "didx","didx2","didx3"

###
### データの取得とグラフの作成
### 

(DateTime.parse("#{ARGV[2]}")..DateTime.now).select{|d| d.day==1}.each do |time_from|

# 7, 30, 90, 120, 240, 360 日の幅で描画  
#[7, 30, 90, 120, 240, 360].each do |range|
#  p "#{range} days"


# 公開ディレクトリの作成
  pubdir_temp = "#{pubdir}/temp/#{time_from.strftime("%Y")}"
  pubdir_humi = "#{pubdir}/humi/#{time_from.strftime("%Y")}"
  pubdir_didx = "#{pubdir}/didx/#{time_from.strftime("%Y")}"
  FileUtils.mkdir_p( pubdir_temp ) until FileTest.exists?( pubdir_temp )
  FileUtils.mkdir_p( pubdir_humi ) until FileTest.exists?( pubdir_humi )
  FileUtils.mkdir_p( pubdir_didx ) until FileTest.exists?( pubdir_didx )

  
  # 配列の初期化
  ops = ["mean","mean1", "min", "max"]
  time_list = Array.new
  temp_list = Hash.new
  humi_list = Hash.new
  didx_list = Hash.new
  
  # csv ファイルの読み込み. 配列化. 統計量ごとにファイルが異なる.
  ops.each do |op|
    
    # 初期化
    time_list     = Array.new
    temp_list[op] = Array.new
    humi_list[op] = Array.new
    didx_list[op] = Array.new

    CSV.foreach( "#{srcdir}/#{myid}_#{op}.csv" ) do |item|

      time = DateTime.parse( "#{item[0]} 00:00:00 JST" ) # 時刻
        
      # 指定期間のデータのみ配列化 (1 日毎の値)
      if time >= time_from

        time_list.push( time )              # 時刻
        temp_list[op].push( item[1].to_f )  # 温度
	humi_list[op].push( item[4].to_f )
	didx_list[op].push( item[15].to_f )
      end
    end
  end
  p "plot from #{time_list[0]} to #{time_list[-1]}"
  
  next if temp_list.min==temp_list.max
  ###
  ### 1 日ごとの統計量. グラフ化. 
  ###

  # 平均値, 最小値, 最大値の比較のグラフ
  Numo.gnuplot do
    set title:	  "#{ARGV[1]}(温度)"
    set ylabel:   "temperature (c)"
    set xlabel:   "time"
    set xdata:    "time"
    set timefmt_x:"%Y-%m-%dT%H:%M:%S+09:00"
    set format_x: "%Y/%m/%d"
    set xtics:    "rotate by -60"
    set terminal: "png"
    set output:   "#{pubdir}/#{myid}_temp_#{time_from.strftime("#%Y%m%d")}.png"
    set key: "box"
    set :datafile, :missing, "999.9"
    
    plot [time_list, temp_list["mean"], using:'1:($2)', with:"linespoints", lc_rgb:"green", lw:3, title:"mean"],
         [time_list, temp_list["mean1"],  using:'1:($2)', with:"linespoints", lc_rgb:"black",  lw:3, title:"mean1"],
         [time_list, temp_list["max"],  using:'1:($2)', with:"linespoints", lc_rgb:"red",  lw:3, title:"max"],
         [time_list, temp_list["min"],  using:'1:($2)', with:"linespoints", lc_rgb:"blue",  lw:3, title:"min"]
  end   


  Numo.gnuplot do
    set title:	  "#{ARGV[1]}(湿度)"
    set ylabel:   "humidity (%)"
    set xlabel:   "time"
    set xdata:    "time"
    set timefmt_x:"%Y-%m-%dT%H:%M:%S+09:00"
    set format_x: "%Y/%m/%d"
    set xtics:    "rotate by -60"
    set terminal: "png"
    set output:   "#{pubdir}/#{myid}_humi_#{time_from.strftime("%Y%m%d")}month.png"
    set key: "box"
    set :datafile, :missing, "999.9"
    
    plot [time_list, temp_list["mean"], using:'1:($2)', with:"linespoints", lc_rgb:"green", lw:3, title:"mean"],
         [time_list, temp_list["mean1"],  using:'1:($2)', with:"linespoints", lc_rgb:"black",  lw:3, title:"mean1"],
         [time_list, temp_list["max"],  using:'1:($2)', with:"linespoints", lc_rgb:"red",  lw:3, title:"max"],
         [time_list, temp_list["min"],  using:'1:($2)', with:"linespoints", lc_rgb:"blue",  lw:3, title:"min"]
  end

  Numo.gnuplot do
    set title:	  "#{ARGV[1]}(不快指数)"
    set ylabel:   "temperature (C)"
    set xlabel:   "time"
    set xdata:    "time"
    set timefmt_x:"%Y-%m-%dT%H:%M:%S+09:00"
    set format_x: "%Y/%m/%d"
    set xtics:    "rotate by -60"
    set terminal: "png"
    set output:   "#{pubdir_didx}/#{myid}_didx_#{time_from.strftime("%Y%m%d")}.png"
    set key: "box"
    set :datafile, :missing, "999.9"
    
    plot [time_list, temp_list["mean"], using:'1:($2)', with:"linespoints", lc_rgb:"green", lw:3, title:"mean"],
         [time_list, temp_list["mean1"],  using:'1:($2)', with:"linespoints", lc_rgb:"black",  lw:3, title:"mean1"],
         [time_list, temp_list["max"],  using:'1:($2)', with:"linespoints", lc_rgb:"red",  lw:3, title:"max"],
         [time_list, temp_list["min"],  using:'1:($2)', with:"linespoints", lc_rgb:"blue",  lw:3, title:"min"]
  end


  # 平均値 + 標準偏差のグラフ作成
#  Numo.gnuplot do
#   set ylabel:   "temperature (C)"
#   set xlabel:   "time"
#   set xdata:    "time"
#   set timefmt_x:"%Y-%m-%dT%H:%M:%S+09:00"
#   set format_x: "%Y/%m/%d"
#   set xtics:    "rotate by -60"
#   set terminal: "png"
#   set output:   "#{pubdir}/#{myid}_temp3_#{range}day.png"
#   set :nokey
#   set :datafile, :missing, "999.9"
   
#   plot time_list,temp_list["mean"],temp_list["stddev"], using:'1:2:3', with:"yerrorbars", lc_rgb:"green", lw:3
#  end   
end
end
