#!/usr/bin/ruby
# coding:utf-8

puts "djvubest"
if ARGV.count < 2
  puts "сборка многостраничного djvu на основе нескольких версий"
  puts "Выходной файл собирается из страниц с меньшим размером"
  puts "использование: djvubest.rb <выходной файл> <файл/директория 1> <файл/директория 2> ... [файл/директория N]"
  exit
end

class Djvu
  attr_accessor :isfile, :path, :tmppath, :pages, :selected
  def initialize(path)
    self.selected=0
    self.path = path
    if File.ftype(path) == 'directory'
      self.isfile = false
      self.pages = Dir["#{self.path}/*.djvu"].sort.map {|i| [i, File.new(i).size]}
    else
      self.isfile = true
      `mkdir #{self.tmppath = "/tmp/djvflat.%s" % [ (1..4).map{|i| ('a'..'z').to_a[rand(26)]}.join ]}`
      raise "Не удалось создать временную директорию #{self.tmppath}" if !$?
      out = `#{cmd = "djvmcvt -i #{self.path} #{self.tmppath} #{self.tmppath}/.index"}`
      raise "Не удалось разобрать djvu: #{cmd}\n#{out}" if !$?
      self.pages = Dir["#{self.tmppath}/*.djvu"].sort.map {|i| [i, File.new(i).size]}
    end
  end
  def clean()
    `rm -Rf #{self.tmppath}` if self.isfile
  end
end

djs = []
npg = nil
begin
  ARGV[1..-1].each do |x|
    djs += [ djvu = Djvu.new(x) ]
    puts "Djvu: %s %d pages" % [ djvu.path, djvu.pages.count]
    raise "Разное число страниц в документах" if npg and npg != djvu.pages.count
    npg = djvu.pages.count
  end
rescue => ex
  puts "Аварийное завершение: #{ex}"
else
  pages = []
  npg.times do |i|
    dsel = djs[0]
    djs[1..-1].each do |d|
      dsel = d if d.pages[i][1] < dsel.pages[i][1]
    end
    puts "%s -> %s" % [djs[0].pages[i][0], dsel.pages[i][0]] if dsel != djs[0]
    dsel.selected += 1
    pages += [dsel.pages[i][0]]
  end
  djs.each { |d| puts "Выбрано %s: %d" % [d.path, d.selected]}
  puts "Сборка файла: %s" % [ARGV[0]]
  `djvm -c #{ARGV[0]} #{pages.join(' ')}`
  puts "Сборка прошла неудачно..." if !$?
end

djs.each { |d| d.clean }
