# encoding: utf-8
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG = nil

require 'yaml'
require_relative 'marks_scrapper'

class Courses
  attr_reader :marks
  attr_reader :courses  
  attr_reader :passed
  attr_reader :average
  attr_reader :categories
  
  def initialize login, password
    @log = Logger.new(File.expand_path('~') +"/log/courses.log", 'daily')

    marksScrapper = MarksScrapper.new login, password
    
    @categories = YAML::load(File.read(File.expand_path('~') +'/.categories.yml'))
    @marks = marksScrapper.marks

    # add category to each mark
    @marks.each do |m|
      id = m[:id].to_s
      
      if @categories[id].nil?
        puts "Error: Cannot find category of course:"
        puts m.inspect
        puts "please edit file categories.yml"
        puts ""
        exit
      end

      m[:category] = @categories[id][:category]
      @log.debug "#{m[:title].to_s.slice(0..49).ljust(50)}#{m[:mark].to_s.center(3)}#{m[:year].to_s.rjust(4)} #{m[:semester]} #{m[:category]}"
    end
    @courses = @marks
    # created passed
    @passed = @marks.select{|c| c[:mark] >= 5}
    
    @categories = ['Βασικα Πρωτης Κατευθυνσης',
                  'Βασικα Δευτερης Κατευθυνσης',
                  'Βασικα Τριτης Κατευθυνσης', 
                  'Υποχρεωτικα', 
                  'Επιλογες Κατευθυνσεων', 
                  'Ελευθερα', 
                  'Γενικης Παιδειας']
                  
   #average
   sum = 0
   @passed.each { |c| sum += c[:mark]}
   @average = (Float(sum) / Float(@passed.size)).round(2)
  end # initialize

  def by_category category
    return @passed.select{|c| c[:category] == category}
  end
  
  def basika
    return @passed.select{|c| (c[:category] == 'Βασικα Πρωτης Κατευθυνσης') | (c[:category] == 'Βασικα Δευτερης Κατευθυνσης') | (c[:category] == 'Βασικα Τριτης Κατευθυνσης') }
  end
  
  def sum_by_category category
    passed = @passed.select{|c| c[:category] == category}
    sum = 0
    passed.each do |c|
      sum += c[:mark]
    end
    return sum
  end
  
  def average_by_category category
    return (Float(sum_by_category category) / Float(by_category(category).size)).round(2)
  end
  
  def print_by_category category
    columns = Integer(`tput cols`)
    courses = by_category(category)
    puts "#{category}  (#{(courses.size)}, #{average_by_category(category)})".center(columns).green
    courses.each do |c|
      if columns > 60
        print c[:title].to_s.slice(0..(columns-38)).ljust(columns-37).blue
      else
        puts  c[:title].to_s.blue
      end  
      print c[:mark].to_s.center(3).green
      print c[:year].to_s
      print " X " if c[:semester] == 1
      print " E " if c[:semester] == 2
      print " Σ " if c[:semester] == 3
      puts c[:category].blue
    end

  end
  
  def print_all
    @categories.each {|cat| print_by_category cat}
    puts
    puts "  Total: #{(@passed.size).to_s.rjust(4)}".red
    puts "Average: #{@average}".red
    puts ""
    puts "Για Πτυχίο Απομένουν:".green
    tmp = 25 - by_category('Υποχρεωτικα').size
    puts "άλλα #{tmp} 'Υποχρεωτικα'".blue if tmp > 0
    
    tmp = by_category('Βασικα Πρωτης Κατευθυνσης').size + by_category('Βασικα Δευτερης Κατευθυνσης').size + by_category('Βασικα Τριτης Κατευθυνσης').size
    puts "άλλα #{5 - tmp} ''Βασικα Κατευθυνσης''".blue if tmp < 5 
    
    puts "άλλo 1 Βασικο Πρωτης Κατευθυνσης".blue if by_category('Βασικα Πρωτης Κατευθυνσης').size == 0
    puts "άλλo 1 Βασικο Δευτερης Κατευθυνσης".blue if by_category('Βασικα Δευτερης Κατευθυνσης').size == 0
    puts "άλλo 1 Τριτης Τριτης Κατευθυνσης".blue if by_category('Βασικα Τριτης Κατευθυνσης').size == 0
    
    if by_category('Ελευθερα').size < 3
      tmp = by_category('Ελευθερα').size
    else
      tmp = 3
    end
    tmp += by_category('Βασικα Πρωτης Κατευθυνσης').size +
          by_category('Βασικα Δευτερης Κατευθυνσης').size +
          by_category('Βασικα Τριτης Κατευθυνσης').size +
          by_category('Επιλογες Κατευθυνσεων').size         
    puts "άλλα #{15 - tmp} Μαθήματα Κατεύθυνσης".blue if tmp < 15
    
    tmp = by_category('Γενικης Παιδειας').size
    puts "άλλα #{5 - tmp} Γενικης Παιδειας".blue if tmp < 5
    
    #puts "+ Πτυχιακή".blue
    puts "\nΜέσος Όρος".green
    
    marks = Array.new
    basika.each {|b| marks << b[:mark]}
    marks.sort!{ |x,y| y <=> x }
    sum=0
    total=0

    i=1
    marks.each do |m|
      if i<=5
        sum+= m*2.0 
        total+= 2.0
      else
        sum+= m*1.5 if i>5
        total+=1.5
      end
      i+=1
    end
    by_category('Επιλογες Κατευθυνσεων').each do |m|
      sum+= m[:mark]*1.5
      total+=1.5
    end
    by_category('Υποχρεωτικα').each do |m|
      sum+= m[:mark]*2.0
      total+=2.0
    end
    by_category('Ελευθερα').each do |m|
      sum+= m[:mark]*1.5
      total+=1.5
    end
    puts "#{'%.3f'%(sum/total)}".red
  end
    
end # class

