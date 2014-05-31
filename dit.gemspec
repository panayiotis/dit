Gem::Specification.new do |s|
  s.name        = 'dit'
  s.version     = '0.0.3'
  s.date        = '2013-02-26'
  s.summary     = "Di Courses"
  s.authors     = ["Panos"]
  s.files       = ["lib/courses.rb","lib/courses_scrapper.rb","lib/marks_scrapper.rb","bin/dit"]
  s.executables << 'dit'
  s.add_dependency "mechanize"
  s.add_dependency "colored"
end
