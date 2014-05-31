# encoding: utf-8
require 'mechanize'
require 'logger'

class MarksScrapper

  attr_accessor :marks

  def initialize(login, password)
  
    @log = Logger.new(File.expand_path('~') +"/log/di_scrapper.log", 'daily')
    
    @login = login
    @password = password
    #file = File.open("page.html", "w")
    agent = Mechanize.new
    agent.user_agent_alias = 'Linux Mozilla'

    @log.debug "Mechanize: get DI site"
    page = agent.get 'https://my-studies.uoa.gr/secr3w/connect.aspx'
    if page.title != "Γραμματείες Πανεπιστημίου Αθηνών"
      @log.error "Mechanize: wrong site title: #{page.title}"
    end
    
    form = page.form_with(:action => 'https://my-studies.uoa.gr/Secr3w/connect.aspx')
    # form.fields.each { |f| puts f.name }

    if form.fields[0].name != "username"
      @log.error "Mechanize: wrong form field name: #{form.fields[0].name}"
    end

    if form.fields[1].name != "password"
      @log.error "Mechanize: wrong form field name: #{form.fields[1].name}"
    end
    
    form.username = @login
    #form.field_with(:name => "name").value = "testaccount"

    form.password = @password

    #form.fields.each { |f| puts f.name + f.value }

    #form.form_id = "user_login"
    @log.debug "Mechanize: submit form"
    page = agent.submit(form, form.buttons.first)


    if !page.body.force_encoding("UTF-8").scan(/Αποτυχία Σύνδεσης:<\/b> Ο λογαριασμός πρόσβασης δεν υπάρχει ή λάθος κωδικός./).empty?
      @log.error "Mechanize: Failed to login: username: #{@login} password: #{@password}"
      raise 'Failed Login' 
    end
    
    page = agent.get 'https://my-studies.uoa.gr/Secr3w/app/accHistory/accadFooter.aspx?'
    
    if page.title != "Γραμματείες Πανεπιστημίου Αθηνών"
      @log.error "Mechanize: wrong site title: #{page.title}"
    end
    
        
    marks = Array.new

    time = Time.now

    page.body.force_encoding("UTF-8").scan(/cAccadArray\[\d+\].+'ΕΞ\((.)\).*(\d\d\d\d).*'.+'(.+)'.+'(.+)'.+'(.+)'.+'.+'.+/) do |semester, year, id, title, mark|
      #puts "#{semester} #{year} #{id} #{title} #{mark}"
      if semester.nil? | year.nil? | id.nil? | title.nil?
        @log.error "Mechanize: Nil attribute: #{semester} #{year} #{id} #{title} #{mark}"
      end
           
      if semester == 'Χ'
        semester = 1
      elsif semester == 'Ε'
        semester = 2
      elsif semester == 'Σ'
        semester = 3
      else
        @log.error "Mechanize: Wrong semester character: #{semester}"
      end
      
      if mark != "null" && !mark.include?(",")
        marks.push({:title => title, 
                      :mark=> Integer(mark), 
                      :semester => Integer(semester),
                      :id => Integer(id),  
                      :year => Integer(year)})
      
      @log.debug "#{semester} #{year} #{id} #{mark} #{title}"          
      #else
      #  marks.push({:title => title, 
      #                :semester => Integer(semester), 
      #                :id => Integer(id),  
      #                :year => Integer(year)})
      end
    end # end scanning
    
    @log.debug "Mechanize: scraped #{marks.size} marks in #{Time.now - time} seconds"
    @log.debug marks.inspect
    @marks = marks
    
  end
end
